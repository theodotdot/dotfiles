from typing import Optional, Callable
from aqt import gui_hooks, mw
from aqt.utils import tooltip, qconnect, showInfo
from aqt.browser import Browser
from aqt.qt import QAction, QMenu
from aqt.operations.scheduling import forget_cards
from anki.cards import Card
from anki.lang import _
from anki.utils import int_time


def truncateString(string, maxSize=17) -> str:
    """Truncate a string to a desired length, default 17"""
    if len(string) > maxSize:
        return string[0:maxSize - 1] + "..."
    else:
        return string


def run_on_configuration_change(function) -> None:
    """Add event listener to addon manager -> config updated"""
    mw.addonManager.setConfigUpdatedAction(__name__, lambda *_: function())


class Config:
    def __init__(self) -> None:
        config = mw.addonManager.getConfig(__name__)
        self._deleteSourceCard: bool = config["delete_source_card"]
        self._mergeHistories: bool = config["merge_histories"]
        self._targetDeck: str = config["target_deck"]
        self._sourceDeck: str = config["source_deck"]

    def save(self):
        """Persist configuration changes back to plugin"""
        mw.addonManager.writeConfig(__name__, {
            "delete_source_card": self._deleteSourceCard,
            "merge_histories": self._mergeHistories
        })

    @property
    def targetDeck(self) -> str:
        """
    Wether or not to delete the original card after transferring the review history.
    Automatically saves on update
    """
        return self._targetDeck

    @property
    def sourceDeck(self) -> str:
        """
    Wether or not to delete the original card after transferring the review history.
    Automatically saves on update
    """
        return self._sourceDeck

    @property
    def deleteSourceCard(self) -> bool:
        """
    Wether or not to delete the original card after transferring the review history.
    Automatically saves on update
    """
        return self._deleteSourceCard

    @deleteSourceCard.setter
    def deleteSourceCard(self, value) -> None:
        self._deleteSourceCard = value
        self.save()

    @property
    def mergeHistories(self) -> bool:
        """
    If true, review histories of two cards will be merged.
    If false, review history of target crad will be wiped before update.
    Automatically saves on update
    """
        return self._mergeHistories

    @mergeHistories.setter
    def mergeHistories(self, value) -> None:
        self._mergeHistories = value
        self.save()


class ReviewHistory:
    def __init__(self) -> None:
        self.config = Config()

        self.createPluginMenu()

        self.browser: (Browser | None) = None
        self.current: (Card | None) = None
        self.menu: (QMenu | None) = None
        self.selectAction: (QAction | None) = None
        self.targetAction: (QAction | None) = None
        self.copyAction: (QAction | None) = None

    def initEvents(self) -> None:
        """
    Listen to proper events in anki ui life cycle:
    * browser_menus_did_init -> Create the menus
    * browser_did_change_row -> Update the menus
    """
        gui_hooks.browser_menus_did_init.append(self.createBrowserMenu)
        gui_hooks.browser_did_change_row.append(lambda _: self.updateMenus())

    def select(self) -> None:
        """Mark currently selected card in browser as selected"""
        self.current = self.selected()
        self.updateMenus()

        tooltip("Selected review history for %d" % self.current.id)

    def transferTo(self) -> None:
        """Transfer review history of previously selected card to current card. Deselect afterwards"""
        self.transferReviewHistory(self.current, self.selected())

        self.current = None
        self.updateMenus()

    def copyTo(self) -> None:
        """Copy review history of previously selected card to current card. Do not deselect afterwards"""
        self.copyReviewHistory(self.current, self.selected())

    def selected(self) -> Optional[Card]:
        """Return the currently selected card from browser, if only one is selected"""
        return self.browser.table.get_single_selected_card()

    def hasSelected(self) -> bool:
        """Check if only one card is selected in the browser"""
        return bool(self.selected())

    def updateMenus(self) -> None:
        """Enable or disable menu actions depending on current selection state"""
        if (self.hasSelected()):
            self.selectAction.setDisabled(
                self.selected().ivl == 0 or (self.selected().id == self.current.id if self.current else False))
            self.targetAction.setDisabled(self.selected().id == self.current.id if self.current else True)
            self.copyAction.setDisabled(self.selected().id == self.current.id if self.current else True)
        else:
            self.selectAction.setDisabled(True)
            self.targetAction.setDisabled(True)
            self.copyAction.setDisabled(True)

        self.menu.setDisabled(
            not (self.selectAction.isEnabled() or self.targetAction.isEnabled() or self.copyAction.isEnabled()))

    def createBrowserMenu(self, browser: Browser) -> None:
        """Create menus in browser and attach its actions"""
        self.browser = browser

        self.menu = QMenu("Transfer review history", self.browser)
        self.selectAction = QAction("Select current selection for transfer", self.browser)
        self.targetAction = QAction(self.getTransferTargetText(), self.browser)
        self.copyAction = QAction(self.getCopyTargetText(), self.browser)

        self.browser.form.menu_Cards.addMenu(self.menu)
        self.menu.addAction(self.selectAction)
        self.menu.addAction(self.targetAction)
        self.menu.addAction(self.copyAction)

        qconnect(self.selectAction.triggered, self.select)
        qconnect(self.targetAction.triggered, self.transferTo)
        qconnect(self.copyAction.triggered, self.copyTo)

        self.updateMenus()

        run_on_configuration_change(self.updateTargetText)

    def updateTargetText(self) -> None:
        """Update target selection text according to delete or merge configuration"""
        try:
            self.targetAction.setText(self.getTransferTargetText())
            self.copyAction.setText(self.getCopyTargetText())
        except:
            pass

    def getTransferTargetText(self) -> str:
        """Return target selection text according to delete configuration"""
        text: str = "Merge review histories into current selection" if self.config.mergeHistories else "Transfer review history to current selection"

        if (self.config.deleteSourceCard):
            text = text + " and delete source afterwards"

        return text

    def getCopyTargetText(self) -> str:
        """Return target selection text according to delete configuration"""
        return "Copy review history into current selection (%s)" % (
            "merge" if self.config.mergeHistories else "replace")

    def createPluginMenu(self) -> None:
        """Create configuration menu in tools menu"""
        deleteCardsOption = QAction("Delete cards after transferring review history", mw, checkable=True,
                                    checked=self.config.deleteSourceCard)
        mergeHistoriesOption = QAction("Merge cards review history", mw, checkable=True,
                                       checked=self.config.mergeHistories)

        menu = mw.form.menuTools.addMenu('Transfer review history')
        menu.addAction(deleteCardsOption)
        menu.addAction(mergeHistoriesOption)

        qconnect(deleteCardsOption.triggered, lambda v: self.updateConfig('deleteSourceCard', v))
        qconnect(mergeHistoriesOption.triggered, lambda v: self.updateConfig('mergeHistories', v))

    def updateConfig(self, key: str, value: bool) -> None:
        """Update delete card configuration"""
        setattr(self.config, key, value)

        if (self.menu):
            self.updateTargetText()

    def transferReviewHistory(self, fromCard: Card, toCard: Card) -> None:
        """
    Transfer review history from one card to another.
    Delete the source afterwards if configured to do so.
    Search and reselect target card afterwards.
    """
        self.transferData(fromCard, toCard, "Transferred", lambda: self.transferInDb(fromCard, toCard))

    def copyReviewHistory(self, fromCard: Card, toCard: Card) -> None:
        """
    Copy review history from one card to another.
    Search and reselect target card afterwards.
    """
        self.transferData(fromCard, toCard, "Copied", lambda: self.copyInDb(fromCard, toCard))

    def copyReviewHistoryModified(self, fromCard: Card, toCard: Card) -> None:
        """
    Copy review history from one card to another.
    Search and reselect target card afterwards.

    Manhhao: runs the modified function instead
    """
        self.transferDataModified(fromCard, toCard, "Copied", lambda: self.copyInDb(fromCard, toCard))

    def transferDataModified(self, fromCard: Card, toCard: Card, keyword: str,
                             withTransaction: Callable[[], None]) -> None:
        """
    Transfer review data from one card to another and call provided callback afterwards.

    Manhhao: This is modified to be ran with my code
    """
        # fromF1 = fromCard.note().fields[0]
        # toF1 = toCard.note().fields[0]

        # mw.progress.start()

        self.copyCardStatsModified(fromCard, toCard)
        self.prepareTargetCard(toCard)

        mw.col.db.transact(withTransaction)
        # mw.progress.finish()

        # self.browser.search()
        # self.browser.table.select_single_card(toCard.id)

        fromCard.load()
        toCard.load()

        # tooltip("%s review history from '%s' to '%s'" % (keyword, truncateString(fromF1), truncateString(toF1)) )

    def transferData(self, fromCard: Card, toCard: Card, keyword: str, withTransaction: Callable[[], None]) -> None:
        """
    Transfer review data from one card to another and call provided callback afterwards.
    """
        fromF1 = fromCard.note().fields[0]
        toF1 = toCard.note().fields[0]

        mw.progress.start()

        self.copyCardStats(fromCard, toCard)
        self.prepareTargetCard(toCard)

        mw.col.db.transact(withTransaction)
        mw.progress.finish()

        self.browser.search()
        self.browser.table.select_single_card(toCard.id)

        fromCard.load()
        toCard.load()

        tooltip("%s review history from '%s' to '%s'" % (keyword, truncateString(fromF1), truncateString(toF1)))

    def copyCardStats(self, fromCard: Card, toCard: Card) -> None:
        """
    Copy card stats from one card to another.
    """
        toCard.type = fromCard.type
        toCard.queue = fromCard.queue
        toCard.ivl = fromCard.ivl
        toCard.factor = fromCard.factor
        toCard.lapses = fromCard.lapses
        toCard.left = fromCard.left
        toCard.due = fromCard.due
        toCard.odue = fromCard.odue
        toCard.desired_retention = fromCard.desired_retention
        toCard.memory_state = fromCard.memory_state
        toCard.mod = int_time()

    def copyCardStatsModified(self, fromCard: Card, toCard: Card) -> None:
        """
        Copy card stats from one card to another.
        """
        # don't modify card if core card hasn't been reviewed yet, it's probably enough to check one of these but eh
        if not (fromCard.reps == 0 and fromCard.ivl == 0):
            toCard.mod = int_time()

            toCard.type = fromCard.type
            toCard.queue = fromCard.queue
            toCard.due = fromCard.due
            toCard.ivl = fromCard.ivl
            toCard.factor = fromCard.factor
            toCard.reps = fromCard.reps
            toCard.lapses = fromCard.lapses
            toCard.left = fromCard.left

            # save correct sorting order in case you reset the card
            toCard.original_position = toCard.due

            toCard.due = fromCard.due
            toCard.odue = fromCard.odue

            toCard.desired_retention = fromCard.desired_retention
            toCard.memory_state = fromCard.memory_state


    def transferInDb(self, fromCard: Card, toCard: Card) -> None:
        """
    Move revlog from one card to another.
    Delete the source afterwards if configured to do so.

    Perform in transaction!
    """
        mw.col.db.all("UPDATE revlog SET cid = ? WHERE cid = ?", toCard.id, fromCard.id)

        if (self.config.deleteSourceCard):
            mw.col.remove_notes_by_card(card_ids=[fromCard.id])
        else:
            mw.col.db.all(
                "UPDATE cards SET mod = %s, type = 0, queue = 0, ivl = 0, factor = 0, reps = 0, lapses = 0, left = 0 WHERE id = ?" % (
                    int_time()), fromCard.id)
            fromCard.load()
            fromCard.desired_retention = None
            fromCard.memory_state = None

            mw.col.update_card(fromCard, skip_undo_entry=True)

    def copyInDb(self, fromCard: Card, toCard: Card) -> None:
        """
    Copy revlog from one card to another.

    Perform in transaction!
    """
        COLUMNS = ['id', 'usn', 'ease', 'ivl', 'lastIvl', 'factor', 'time', 'type']
        ROWS = ', '.join(COLUMNS)
        QUERY = 'select %s from revlog where cid = ?' % ROWS

        for row in mw.col.db.all(QUERY, fromCard.id):
            sql = 'insert into revlog (%s, cid) values (%s, %s, %s)' % (
            ROWS, self.getNextId(row[0]), ', '.join(map(str, row[1:])), toCard.id)

            mw.col.db.all(sql)

    def getNextId(self, rootId: int) -> int:
        "Return the nearest non-conflicting timestamp id for revlog."
        timestamp = rootId

        while mw.col.db.scalar(f"select id from revlog where id = ?", timestamp):
            timestamp += 1

        return timestamp

    def prepareTargetCard(self, toCard: Card) -> None:
        """
    Prepare actual data transfer:
    * Persist card changes in database

    Perform in transaction!
    """
        # As it is not easily doable to transfer the review data by anki itself
        # We do not allow undoing this action.
        # Deleting the card though will be undoable by default
        mw.col.update_card(toCard, skip_undo_entry=True)

        if not self.config.mergeHistories:
            mw.col.db.all("DELETE FROM revlog WHERE cid = ?", toCard.id)


review_history = ReviewHistory()
review_history.initEvents()


def run_transfer() -> None:
    # deck from where review history should be copied from
    source_deck = mw.col.decks.by_name(review_history.config.sourceDeck)
    source_cards = mw.col.decks.cids(source_deck["id"])

    # where to copy review history to
    target_deck = mw.col.decks.by_name(review_history.config.targetDeck)
    target_cards = mw.col.decks.cids(target_deck["id"])

    c = transfer_history(source_cards, target_cards)

    showInfo("updated: %d cards" % c)


def transfer_history(source, target):
    counter = 0
    source_cards = [mw.col.get_card(card_id) for card_id in source]
    target_cards = [mw.col.get_card(card_id) for card_id in target]
    for card_to_update in target_cards:
        note_to_update = card_to_update.note()

        word = str(note_to_update["Word"])
        word_reading = str(note_to_update["Word Reading"])

        for c in source_cards:
            n = c.note()

            c_word = str(n["Word"])
            c_word_reading = str(n["Word Reading"])

            if word == c_word and word_reading == c_word_reading:
                review_history.copyReviewHistoryModified(c, card_to_update)
                print(str(card_to_update.id) + " " + str(c.id))
                print("updated " + word)
                counter = counter + 1
    return counter


action = QAction("Review History to Kaishi 1.5k", mw)
qconnect(action.triggered, run_transfer)
mw.form.menuTools.addAction(action)
