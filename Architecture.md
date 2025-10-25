# Architecture Document 
**iOS Video Feed Application**  
*Date: October 25, 2025*

---

## 1. Overall Architecture Approach

### MVP (Model-View-Presenter) + Dependency Injection Pattern
The app follows the Model-View-Presenter pattern, using protocols and dependency injection to keep everything clean and easy to test.

```
┌─────────────────┐
│   UI View       │ ← Passive View (UI Rendering)
│ (VideoFeedView) │   • Displays data
└────────┬────────┘   • Forwards user actions
         │ Watches @Published state
         ↓
┌─────────────────┐
│    Presenter    │ ← Presentation Logic
│ (@MainActor)    │   • Manages state
│ @ObservableObj  │   • Coordinates services
└────────┬────────┘   • Formats data for View
         │ Uses
         ↓
┌─────────────────┬─────────────────┬──────────┐
│     Model       │ NetworkService  │ PlayerMgr│ ← Model & Services
│    (Video)      │   (Protocols)   │(Protocol)│
└─────────────────┴─────────────────┴──────────┘
```

**Why MVP, not MVVM:**
Here, the Presenter acts as the brains—VideoFeedPresenter handles all the logic and state. The view, like VideoFeedView, just listens and draws what it's told. It never touches the business logic.

**Main Pieces:**
- View Layer: UI views like VideoFeedView and VideoPlayerView. They're just the face—watching for changes and updating the UI when needed.
- Presenter Layer: VideoFeedPresenter. This part runs the show, handling logic, keeping track of state, and directing services.
- Model Layer: Video and VideoFeedResponse. They're just data holders.
- Service Layer: NetworkService makes API calls, and VideoPlayerManager takes care of everything video playback.
- Dependency Container: DIContainer handles all the dependencies in one spot, setting things up only when you need them.

### Protocol-Oriented Design
Every service is built around a protocol—think NetworkServiceProtocol or VideoPlayerManagerProtocol. That means you can:
- Easily swap in mock versions for unit tests
- Change how things work without breaking everything else
- Clearly define how each layer talks to the next
- Inject any dependency right into the Presenter

### Why MVP Works Here
- You can test Presenter logic without touching the UI.
- The View doesn't know a thing about networking or playback—just UI.
- One Presenter works with any number of views.
- Each part does one job: View draws, Presenter manages state, Services handle the heavy lifting.
- ObservableObject and Published keep everything reactive and up to date.

---

## 2. Key Design Decisions & Trade-offs

### Decision 1: LazyVStack with ScrollViewReader
**Rationale:** Used `LazyVStack` instead of loading all video views upfront to conserve memory.

**Trade-offs:**
- **Pro**: Only renders visible and immediate adjacent video cells
- **Pro**: Scales to large video feeds without memory issues
- **Con**: Slight lag when scrolling very rapidly (mitigated by prefetching)

### Decision 2: Centralized VideoPlayerManager
**Rationale:** Single source of truth for all AVPlayer instances with lifecycle management.

**Trade-offs:**
- **Pro**: Prevents several players for one video (memory efficient)
- **Pro**: Pause/play coordination centralized (a single video plays at a time)
- **Pro**: Cleanup and memory management are easier
- **Con**: Requires careful synchronization (achieved using `@MainActor` and `setupInProgress` set)

### Decision 3: HLS Video Format
**Rationale:** Preferred HLS (HTTP Live Streaming) URLs for adaptive streaming.

**Trade-offs:**
- **Pro**: Adaptive bitrate adjusts to network conditions automatically
- **Pro**: Better user experience on varying network speeds
- **Pro**: Industry standard for iOS video streaming
- **Con**: Requires CDN support (already provided by API)

### Decision 4: Async/Await with Swift Concurrency
**Rationale:** Leveraged modern Swift concurrency over callbacks or Combine-only approach.

**Trade-offs:**
- **Pro**: Readable and maintainable asynchronous code
- **Pro**: `@MainActor` ensures UI updates are on main thread safely
- **Pro**: Structured concurrency prevents race conditions
- **Con**: Requires iOS 15+ (alright for new apps)

### Decision 5: Muted Audio by Default
**Rationale:** All videos start muted (`player.isMuted = true`, `player.volume = 0.0`).

**Trade-offs:**
- **Pro**: Matches user expectations (TikTok/Instagram pattern)
- **Pro**: Prevents audio overlap on quick scrolling
- **Pro**: More battery-efficient
- **Con**: Requires future UI controls for unmuting (not in MVP)

---

## 3. Memory Management Strategy

### Player Instance Management
**Problem:** AVPlayer instances are memory-intensive. Preloading players for every video would cause crashes.

**Solution:**
```swift
private var players: [String: AVPlayer] = [:]  // Dictionary cache
```
- **Reuse Pattern**: Players are cached by video ID and reused when scrolling back
- **Lazy Setup**: Players are only created when needed via `setupPlayer(for:url:)`
- **Concurrent Setup Prevention**: `setupInProgress` set prevents duplicate player creation

### Aggressive Prefetching Strategy
**Current Index + Adjacent Videos:**
```swift
// On initial load: prefetch first 3 videos
for video in videos.prefix(3) {
    // prefetch logic
}

// On scroll: prefetch next video
let nextIndex = index + 1
if nextIndex < videos.count {
    _ = await playerManager.setupPlayer(for: videos[nextIndex].id, url: url)
}
```
**Benefits:**
- Seamless transitions (next video is pre-buffered)
- Low memory footprint (only 2-3 players active)
- Background prefetching does not block UI

### Cleanup & Lifecycle
**Comprehensive cleanup on refresh or app termination:**
```swift
func cleanup() {
    // Remove notification observers (prevent memory leaks)
    for observer in loopObservers.values {
        NotificationCenter.default.removeObserver(observer)
    }

    // Release resources and stop playback
    for player in players.values {
        player.pause()
        player.replaceCurrentItem(with: nil)  // Crucial: releases video memory
    }

    players.removeAll()
}
```

### Audio Session Configuration
```swift
try AVAudioSession.sharedInstance().setCategory(
    .playback,
    mode: .moviePlayback,
    options: [.mixWithOthers]
)
```
- Correct audio handling without disrupting other apps
- Set once upon initialization for performance

---

## 4. Smooth Transitions Strategy

### Technique 1: Paging Scroll Behavior
```swift
.scrollTargetBehavior(.paging)
.scrollPosition(id: $currentIndex)
```
- iOS paging gives you that snap-to-page feel, just like scrolling through TikTok. Animations slow down and settle in smoothly when you stop, so the transition feels natural. Use containerRelativeFrame(.vertical) to make sure each video cell fills the screen.

### Technique 2: Prefetching Adjacent Videos

- No one likes waiting for a video to load. While you’re watching video N, the app’s already working on getting N+1 ready in the background. On the first load, it grabs the first three videos right away so you can just keep scrolling. Background prefetching uses async/await, so the UI never freezes or lags.

### Technique 3: Playback Coordination
- Only one video plays at a time:
```swift
func play(videoId: String) async {
    // Pause all other videos
    for (id, player) in players where id != videoId {
        player.pause()
    }
    // Play requested video
    players[videoId]?.play()
}
```
- This way, it prevents audio/video conflicts, and reduces CPU/GPU load during transitions

### Technique 4: Video Looping
- Seamless playback:
```swift
NotificationCenter.default.addObserver(
    forName: .AVPlayerItemDidPlayToEndTime,
    object: playerItem,
    queue: .main
) { [weak player] _ in
    player?.seek(to: .zero) { finished in
        if finished { player?.play() }
    }
}
```
- When a video ends, it just starts over by itself. The seek animation is smooth, so you don’t see any glitch or obvious reset.

### Technique 5: Buffer Duration Optimization
```swift
playerItem.preferredForwardBufferDuration = 2.0
```
- Only buffer two seconds ahead. This way, videos start faster and the app doesn’t hog memory. AVPlayer’s automaticallyWaitsToMinimizeStalling takes care of adjusting the stream if your connection changes.

### Technique 6: Readiness Polling
```swift
var attempts = 0
while attempts < 30 {
    if item.status == .readyToPlay { return player }
    try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms
    attempts += 1
}
```
- Before playing, the app checks if the player’s actually ready. No more awkward black flashes between videos. And if it takes longer than three seconds, it just gives up—nobody’s waiting forever.

---

## 5. Testing & Quality Assurance

### Test Coverage
- Unit tests in `FeedTests.swift` cover the presenter logic, the network layer, and how errors get handled.
- Service protocols make it easy to plug in test doubles with dependency injection.
- The new `async/await` syntax really simplifies testing async flows.

### Error Handling
- Network errors show clear, friendly messages to users.
- There's a retry option, so the app can bounce back from temporary failures.
- Loading states keep users in the loop about what's happening.

---

## 6. Future Enhancements

Some ideas to push this even further in production:

1. **Unit Tests**: Fill out `FeedTests.swift` with more cases, especially for edge scenarios and tougher network cases.
2. **Memory Management**: Watch for `didReceiveMemoryWarning` and clear out any distant player cache, keeping only videos close to the user.
3. **Analytics**: Track things like video completion, scroll activity, engagement, and total watch time to understand usage better.
4. **Audio Controls**: Add a mute/unmute toggle and a volume slider—right now, all videos play muted.
5. **Progressive Quality**: Start streams in lower quality and jump to HD once there's enough buffer.
6. **Infinite Scroll**: Use pagination to keep loading more videos as users near the end of the feed.
7. **Pull-to-Refresh**: Add a swipe-down gesture to reload the feed, not just a retry button after errors.
8. **Video Caching**: Store video segments on the device to speed up replays or allow offline viewing.
9. **Engagement UI**: Bring in buttons for likes, comments, and shares, just like other social video apps.
10. **Background Playback**: Let audio keep playing if the app goes into the background—right now, it stops.

---

## Conclusion

This setup puts performance, memory efficiency, and a smooth user experience first, without making the codebase messy or hard to test. With modern Swift concurrency, a protocol-driven approach, and smart prefetching, the app delivers a professional-grade video feed that scales well and feels great to use.
