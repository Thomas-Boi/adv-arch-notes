//
//  Copyright © Borna Noureddin. All rights reserved.
//

import GLKit

extension ViewController: GLKViewControllerDelegate {
    func glkViewControllerUpdate(_ controller: GLKViewController) {
        glesRenderer.update();
        
    }
}

extension ViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    return true
  }
}

class ViewController: GLKViewController {
    
    
    private var context: EAGLContext?
    private var glesRenderer: Renderer!  // ###
    private var dragStart: CGPoint!

    private func setupGL() {
        context = EAGLContext(api: .openGLES3)
        EAGLContext.setCurrent(context)
        if let view = self.view as? GLKView, let context = context {
            view.context = context
            delegate = self as! GLKViewControllerDelegate
            glesRenderer = Renderer()
            glesRenderer.setup(view)
            glesRenderer.loadModels()
        }
        
        glesRenderer.xRot = 30 * Float.pi / 180
        glesRenderer.yRot = 30 * Float.pi / 180
        
        let doubleClick = UITapGestureRecognizer(target: self, action: #selector(doDoubleTap))
        doubleClick.numberOfTapsRequired = 2
        doubleClick.delegate = self as! UIGestureRecognizerDelegate
        self.view.addGestureRecognizer(doubleClick)

        let rotObj = UIPanGestureRecognizer(target: self, action: #selector(doRotate))
        rotObj.minimumNumberOfTouches = 1
        rotObj.maximumNumberOfTouches = 1
        rotObj.delegate = self as! UIGestureRecognizerDelegate
        self.view.addGestureRecognizer(rotObj)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGL()
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glesRenderer.draw(rect);
    }
    
    @objc func doDoubleTap(recognizer:UITapGestureRecognizer)
    {
        glesRenderer.isRotating = !glesRenderer.isRotating
    }

    @objc func doRotate(recognizer:UIPanGestureRecognizer)
    {
        if (recognizer.state != UIGestureRecognizer.State.ended) {
            if (recognizer.state == UIGestureRecognizer.State.began) {
                dragStart = recognizer.location(in: self.view)
            } else {
                var newPt = recognizer.location(in: self.view)
                glesRenderer.yRot = Float(newPt.x - dragStart.x) * Float.pi / 180
                glesRenderer.xRot = Float(newPt.y - dragStart.y) * Float.pi / 180
            }
        }
    }
    
 }
