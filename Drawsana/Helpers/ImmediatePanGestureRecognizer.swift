//
//  ImmediatePanGestureRecognizer.swift
//  Drawsana
//
//  Created by Steve Landey on 8/14/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

/**
 Replaces a tap gesture recognizer and a pan gesture recognizer with just one
 gesture recognizer.

 Lifecycle:
 * Touch begins, state -> .began (all other touches are completely ignored)
 * Touch moves, state -> .changed
 * Touch ends
   * If touch moved more than 10px away from the origin at some point, then
     `hasExceededTapThreshold` was set to `true`. Target may use this to
     distinguish a pan from a tap when the gesture has ended and act
     accordingly.

 This behavior is better than using a regular UIPanGestureRecognizer because
 that class ignores the first ~20px of the touch while it figures out if you
 "really" want to pan. This is a drawing program, so that's not good.
 */
class ImmediatePanGestureRecognizer: UIGestureRecognizer {
  var tapThreshold: CGFloat = 10
  // If gesture ends and this value is `true`, then the user's finger moved
  // more than `tapThreshold` points during the gesture, i.e. it is not a tap.
  private(set) var hasExceededTapThreshold = false

  private var startPoint: CGPoint = .zero
  private var lastLastPoint: CGPoint = .zero
  private var lastLastTime: CFTimeInterval = 0
  private var lastPoint: CGPoint = .zero
  private var lastTime: CFTimeInterval = 0
  private var trackedTouch: UITouch?

  var velocity: CGPoint? {
    guard let view = view, let trackedTouch = trackedTouch else { return nil }
    let delta = trackedTouch.location(in: view) - lastLastPoint
    let deltaT = CGFloat(lastTime - lastLastTime)
    return CGPoint(x: delta.x / deltaT , y: delta.y - deltaT)
  }

  override func location(in view: UIView?) -> CGPoint {
    guard let view = view else {
      return lastPoint
    }
    return view.convert(lastPoint, to: view)
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    guard trackedTouch == nil, let firstTouch = touches.first, let view = view else { return }
    trackedTouch = firstTouch
    startPoint = firstTouch.location(in: view)
    lastPoint = startPoint
    lastTime = CFAbsoluteTimeGetCurrent()
    lastLastPoint = startPoint
    lastLastTime = lastTime
    state = .began
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    guard
      state == .began || state == .changed,
      let view = view,
      let trackedTouch = trackedTouch,
      touches.contains(trackedTouch) else
    {
      return
    }

    lastLastTime = lastTime
    lastLastPoint = lastPoint
    lastTime = CFAbsoluteTimeGetCurrent()
    lastPoint = trackedTouch.location(in: view)
    if (lastPoint - startPoint).length >= tapThreshold {
      hasExceededTapThreshold = true
    }

    state = .changed
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard
      state == .began || state == .changed,
      let trackedTouch = trackedTouch,
      touches.contains(trackedTouch) else
    {
      return
    }

    state = .ended

    DispatchQueue.main.async {
      self.reset()
    }
  }

  override func reset() {
    super.reset()
    trackedTouch = nil
    hasExceededTapThreshold = false
  }
}

class PinchRotateGestureRecognizer: UIGestureRecognizer{

    var firstTrackedTouch: UITouch? = nil
    var secondTrackedTouch: UITouch? = nil
    var firstTouchStartPoint: CGPoint = .zero
    var secondTouchStartPoint: CGPoint = .zero
    var firstTouchEndPoint: CGPoint {
        if let view = view, let firstTrackedTouch = firstTrackedTouch{
            return firstTrackedTouch.location(in: view)
        } else {
            return .zero
        }
    }
    var secondTouchEndPoint: CGPoint {
        if let view = view, let secondTrackedTouch = secondTrackedTouch{
            return secondTrackedTouch.location(in: view)
        } else {
            return .zero
        }
    }

    private var startLength: CGFloat{
        return hypot(secondTouchStartPoint.x - firstTouchStartPoint.x, secondTouchStartPoint.y - firstTouchStartPoint.y)
    }

    var scale: CGFloat {
        return hypot(secondTouchEndPoint.x - firstTouchEndPoint.x, secondTouchEndPoint.y - firstTouchEndPoint.y) / startLength
    }
    var rotation: CGFloat {
        return angleBetweenLinesInRadians(line1Start: firstTouchStartPoint, line1End: secondTouchStartPoint, line2Start: firstTouchEndPoint, line2End: secondTouchEndPoint)
    }

    private func angleBetweenLinesInRadians( line1Start: CGPoint, line1End: CGPoint, line2Start: CGPoint, line2End: CGPoint) -> CGFloat {
        let a0 = atan2(Double(line1Start.y - line1End.y), Double(line1Start.x - line1End.x))
        let a1 = atan2(Double(line2Start.y - line2End.y), Double(line2Start.x - line2End.x))

        return CGFloat(a1 - a0)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard touches.count == 2, let view = view else {
            return
        }

        firstTrackedTouch = touches.first
        for touch in touches{
            if touch != firstTrackedTouch{
                secondTrackedTouch = touch
            }
        }

        firstTouchStartPoint = firstTrackedTouch!.location(in: view)
        secondTouchStartPoint = secondTrackedTouch!.location(in: view)

        state = .began
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state == .began || state == .changed,
            touches.count == 2,
            let firstTrackedTouch = firstTrackedTouch,
            let secondTrackedTouch = secondTrackedTouch,
            touches.contains(firstTrackedTouch),
            touches.contains(secondTrackedTouch)
            else
        {
            return
        }

        state = .changed
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard state == .began || state == .changed,
            touches.count == 2,
            let firstTrackedTouch = firstTrackedTouch,
            let secondTrackedTouch = secondTrackedTouch,
            touches.contains(firstTrackedTouch),
            touches.contains(secondTrackedTouch)
            else
        {
            state = .failed
            return
        }

        state = .ended

        DispatchQueue.main.async {
            self.reset()
        }
    }

    override func reset() {
        super.reset()
        firstTrackedTouch = nil
        secondTrackedTouch = nil
    }
}
