//
//  ViewController.swift
//  DemoARApp
//
//  Created by Anton on 15.09.2021.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var deleteDirectionButton: UIButton!
    @IBOutlet weak var getDirectionButton: UIButton!
    private var locationManager = LocationManager()
    private var arrowNode: SCNNode?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneViewInitiate()
        coreLocationInitiate()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravityAndHeading
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func deleteDirectionButtonTapped(_ sender: Any) {
        deleteDirectionArrow()
    }
    
    @IBAction func getDirectionButtonTapped(_ sender: Any) {
        setDirectionArrow()
    }
}

extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        guard let label = messageLabel else { return }
        label.text = error.localizedDescription
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        guard let label = messageLabel else { return }
        label.text = "сессия прервана"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        guard let label = messageLabel else { return }
        label.text = "сессия возобновлена"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            label.text = Constants.setArrow
        }
    }
}

extension ViewController {
    func configureUI() {
        deleteDirectionButton.layer.cornerRadius = 5
        deleteDirectionButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 3, bottom: 8, right: 3)
        getDirectionButton.layer.cornerRadius = 5
        getDirectionButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 3, bottom: 8, right: 3)
        messageLabel?.text = Constants.setArrow
    }
    
    func sceneViewInitiate() {
        sceneView.delegate = self
        let scene = SCNScene()        
        sceneView.scene = scene
    }
    
    func coreLocationInitiate() {
        locationManager.initialize()
        locationManager.delegate = self
    }
    
    func setDirectionArrow() {
        arrowNode = makeDirectionArrow()
        guard let arrowNode = arrowNode else { return }
        arrowNode.scale = SCNVector3(0.1, 0.1, 0.1)
        arrowNode.position = SCNVector3(0.0, 0.0, 0.8)
        sceneView.scene.rootNode.addChildNode(arrowNode)
    }
    
    func deleteDirectionArrow() {
        arrowNode?.removeFromParentNode()
        arrowNode = nil
    }
    
    func makeDirectionArrow() -> SCNNode {
        let vertcount = 48
        let verts: [Float] = [ -1.4923, 1.1824, 2.5000, -6.4923, 0.000, 0.000, -1.4923, -1.1824, 2.5000, 4.6077, -0.5812, 1.6800, 4.6077, -0.5812, -1.6800, 4.6077, 0.5812, -1.6800, 4.6077, 0.5812, 1.6800, -1.4923, -1.1824, -2.5000, -1.4923, 1.1824, -2.5000, -1.4923, 0.4974, -0.9969, -1.4923, 0.4974, 0.9969, -1.4923, -0.4974, 0.9969, -1.4923, -0.4974, -0.9969 ];
        
        let facecount = 13;
        let faces: [CInt] = [  3, 4, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 0, 1, 2, 3, 4, 5, 6, 7, 1, 8, 8, 1, 0, 2, 1, 7, 9, 8, 0, 10, 10, 0, 2, 11, 11, 2, 7, 12, 12, 7, 8, 9, 9, 5, 4, 12, 10, 6, 5, 9, 11, 3, 6, 10, 12, 4, 3, 11 ];
        
        let vertsData  = NSData(bytes: verts,
                                length: MemoryLayout<Float>.size * vertcount)
        
        let vertexSource = SCNGeometrySource(data: vertsData as Data,
                                             semantic: .vertex,
                                             vectorCount: vertcount,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<Float>.size * 3)
        
        let polyIndexCount = 61;
        let indexPolyData  = NSData(bytes: faces, length: MemoryLayout<CInt>.size * polyIndexCount)
        
        let element = SCNGeometryElement(data: indexPolyData as Data,
                                          primitiveType: .polygon,
                                          primitiveCount: facecount,
                                          bytesPerIndex: MemoryLayout<CInt>.size)
        
        let arrowGeometry = SCNGeometry(sources: [vertexSource], elements: [element])
        
        let material = arrowGeometry.firstMaterial!
        
        material.diffuse.contents = UIColor(red: 0.14, green: 0.82, blue: 0.95, alpha: 1.0)
        material.lightingModel = .lambert
        material.transparency = 1.00
        material.transparencyMode = .dualLayer
        material.fresnelExponent = 1.00
        material.reflective.contents = UIColor(white:0.00, alpha:1.0)
        material.specular.contents = UIColor(white:0.00, alpha:1.0)
        material.shininess = 1.00
        
        let arrowNode = SCNNode(geometry: arrowGeometry)
        return arrowNode
    }
}

extension ViewController: LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManager, didEnterRegionId regionId: String) {
        print("You are in the region \(regionId)")
    }
    
    func locationManager(_ locationManager: LocationManager, didExitRegionId regionId: String) {
        print("You are not in the region \(regionId)")
    }
    
    
}
