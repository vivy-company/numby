# Tab Bar and Sidebar Layout Issue

## Summary

Numby uses the native macOS tab bar (`NSTabBar`) in the titlebar together with a full‑height history sidebar implemented via `NSSplitViewController`. To make everything line up with the traffic‑light buttons and the sidebar toggle, we added custom Auto Layout constraints around the tab bar accessory view. Those constraints caused two classes of problems:

- Crashes with `NSInternalInconsistencyException: changing the view's origin is not allowed` when AppKit was animating tab additions/removals.
- Incorrect layout where, on first launch with the sidebar collapsed, the tab strip appears as a tiny cluster in the top‑left corner and does not fill the available titlebar width until the sidebar is opened and a history item is used to create a new tab.

## Original Behaviour

1. Open Numby in a new window with the sidebar hidden.
2. Press `⌘T` or use **File → New Tab** several times.
3. The tabs appear, but they are packed into a small area near the traffic‑light buttons instead of spanning the toolbar.
4. When the history sidebar is later opened and a session is restored into a new tab, the tab bar suddenly jumps into the “correct” full‑width position with the expected spacing.

In earlier iterations, attempting to push the tab bar away from the traffic lights and sidebar by constraining the accessory view itself produced runtime assertions from AppKit:

> `NSInternalInconsistencyException: changing the view's origin is not allowed; NSTitlebarAccessoryViewController _auxiliaryViewFrameChanged`

This happened because we were moving the frame of the accessory view while AppKit’s own layout code was in the middle of its `_auxiliaryViewFrameChanged` handling.

## Design Constraints

- We cannot change the frame (origin/size) of the titlebar accessory wrapper view that AppKit owns.
- We *can* add constraints inside that wrapper to influence where the internal `NSTabBar` sits, as long as those constraints only affect subviews.
- The tab bar must:
  - Leave room on the left for the traffic lights and the sidebar toggle button.
  - Respect the live sidebar width (collapsed vs. expanded, and when the split view is resized).
  - Use the full remaining titlebar width so tabs do not look compressed on one side.
  - Have a height that visually matches the circular toolbar buttons but stays slimmer than the default tab bar.

## Current Implementation

The current approach in `NumbyWindow` (`AppDelegate.swift`) is:

- Detect the tab bar accessory in `addTitlebarAccessoryViewController` and call `setupTabBarConstraints(_:)` once the accessory’s view hierarchy has been created.
- Inside `setupTabBarConstraints`:
  - Grab the accessory view (the view that hosts `NSTabBar`).
  - Constrain its width to match the toolbar width to encourage full‑width usage, without touching its origin.
  - Find the `NSTabBar` subview via `firstDescendant(withClassName: "NSTabBar")`.
  - Insert an invisible **spacer view** pinned to the accessory’s leading edge and to the top/bottom.
  - Give the spacer a width equal to `tabBarLeadingInset()`, which is:
    - `currentSidebarWidth + sidebarToTabsSpacing` when the sidebar is visible, or
    - `windowButtonsBackdropWidth + toolbarControlsMinWidth` when it is collapsed.
  - Pin the tab bar’s leading edge to the spacer’s trailing edge, its trailing edge to the accessory’s trailing edge (with a small negative constant), and center it vertically with a fixed height computed by `targetTabBarHeight(for:)`.
- `MainSplitViewController` broadcasts `sidebarWidthDidChange` notifications whenever the sidebar is toggled or its split ratio changes; each `NumbyWindow` listens and updates `currentSidebarWidth`, which in turn updates the spacer width.

This keeps the tab strip correctly offset from the traffic lights and sidebar toggle, and it reduces the tab height so that the pills and the system `+` button feel visually aligned.

## Known Remaining Problem

When a new window is opened with the sidebar collapsed and tabs are created *before* any sidebar width notification is delivered, AppKit still occasionally lays out the `NSTabBar` using its intrinsic content size first. In that initial layout pass the spacer is present but the accessory view’s width and the tab bar’s internal layout have not fully settled, so:

- Tabs appear bunched near the left (minimum width), even though the spacer and trailing constraints exist.
- After the user opens the sidebar and/or triggers a history‑driven tab creation, a later layout pass recomputes sizes and the tab strip snaps into the expected full‑width configuration.

In other words, the constraints are correct once the system has a stable toolbar layout and a known sidebar width, but the very first layout pass for a brand‑new window can still produce a compressed tab bar.

## Possible Future Improvements

Ideas to make the behaviour fully robust:

- **Force an initial width pass**: After the window becomes key and the toolbar has been laid out, explicitly call `setupTabBarConstraints` again (or a lightweight `refreshTabBarLayout`) to recompute the spacer width using the final accessory bounds.
- **Use a more generous initial inset**: Start with a large default spacer width (e.g. assuming the sidebar is visible) and shrink it once real sidebar width is known, so the worst‑case layout is “too much empty space” rather than “tabs collapsed to the left”.
- **Observe tab group changes**: Listen for tab‑group notifications (e.g. `NSWindow.didChangeOcclusionStateNotification` combined with `tabGroup` inspection) to know when AppKit has finished creating the native tab bar and only then apply our constraints.

For now, the crash has been eliminated and tab height/spacing are correct after the first full layout pass, but the initial layout in a fresh window with a collapsed sidebar still needs refinement.

