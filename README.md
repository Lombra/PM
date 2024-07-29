# Telecom

Telecom provides management for private conversations by moving them into a separate window. It aims to be fairly simple in design, limiting features to ones related to private chatting and chat participants.

**Major features include:**

- Active conversations in a list
- Conversation logs are stored until closed by default (including between sessions)
- Display all Battle.net friends in list by default, eg even ones without active conversation (much like how IMs work)
- Last whispered target remembered between sessions (eg reply keybind)
- Game info summary for Battle.net friends

**Known issues/limitations:**

- Due to presence IDs (an identifier used for Real ID friends) changing between sessions, and the addon's consequential reliance on BattleTags, Real ID friends that has no BattleTag may not have their threads saved between sessions.
- Messages sent from the desktop client doesn't always play nice (Blizzard's fault though, really)
