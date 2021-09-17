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
    // MARK: - Properties
    private var locationManager = CLLocationManager()
    private var arrowNode: SCNNode?
    private var distance: Double = 0
    private var course: Double = 0
    private var trackedLocation: CLLocationCoordinate2D?
    
    // MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var deleteDirectionButton: UIButton!
    @IBOutlet weak var getDirectionButton: UIButton!
    
    // MARK: - Actions
    @IBAction func deleteDirectionButtonTapped(_ sender: Any) {
            deleteArrow()
    }
    
    @IBAction func getDirectionButtonTapped(_ sender: Any) {
            addArrow()
        print(course)
    }
}

extension ViewController {
    
    // MARK: - View Management
    override func viewDidLoad() {
        super.viewDidLoad()
        initSceneView()
        initScene()
        initARSession()
        configureUI()
        configureLocationManager()
        loadArrowModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func initSceneView() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.delegate = self
    }
    
    private func initScene() {
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    private func configureUI() {
        deleteDirectionButton.layer.cornerRadius = 5
        deleteDirectionButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 3, bottom: 8, right: 3)
        getDirectionButton.layer.cornerRadius = 5
        getDirectionButton.titleEdgeInsets = UIEdgeInsets(top: 8, left: 3, bottom: 8, right: 3)
        messageLabel?.text = Constants.setArrow
        distanceLabel?.text = ""
        errorLabel?.isHidden = true
        distanceLabel?.isHidden = true
    }
    
    private func initARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            setTextToErrorLabel("AR сессия не поддерживается")
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        configuration.providesAudioData = false
        sceneView.session.run(configuration)
    }
}

extension ViewController: ARSCNViewDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        setTextToErrorLabel(error.localizedDescription)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        setTextToErrorLabel("сессия прервана")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        setTextToMessageLabel(Constants.setArrow)
        setTextToErrorLabel("сессия возобновлена")
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        setTextToErrorLabel("Authorization status changed to: \(manager.authorizationStatus)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            trackedLocation = Constants.locationMurmansk
            guard let currentLocation = locations.last else { return }
            guard let trackedLocation = trackedLocation else { return }
            let location = CLLocation(latitude: trackedLocation.latitude, longitude: trackedLocation.longitude)
            distance = currentLocation.distance(from: location)
            course = bearing(from: currentLocation, to: location)
            distanceLabel?.isHidden = false
            distanceLabel?.text = get(distance)
        default:
            setTextToErrorLabel("для определения местоположения нужно разрешить отслеживать ваше геоположение")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        setTextToErrorLabel(error.localizedDescription)
    }
    
    private func get(_ distanse: Double) -> String {
        if distance < 1000 {
            return "до цели \(String(format: "%.1f", distance)) м"
        } else {
            return "до цели \(String(Int(distance / 1000))) км"
        }
    }
    
    private func bearing(from currentLocation: CLLocation, to destination: CLLocation) -> Double {
        let lat1 = .pi * currentLocation.coordinate.latitude / 180.0
        let long1 = .pi * currentLocation.coordinate.longitude / 180.0
        let lat2 = .pi * destination.coordinate.latitude / 180.0
        let long2 = .pi * destination.coordinate.longitude / 180.0

        let rads = atan2(
            sin(long2 - long1) * cos(lat2),
            cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(long2 - long1))
        print(rads * 180 / .pi)
        
        return rads
    }
}

extension ViewController {
    private func configureLocationManager() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setTextToMessageLabel(_ text: String) {
        guard let label = messageLabel else { return }
        label.text = text
    }
    
    private func setTextToErrorLabel(_ text: String) {
        guard let label = errorLabel else { return }
        label.isHidden = false
        label.text = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            label.isHidden = true
        }
    }
    
    func addArrow() {
        guard let arrowNode = arrowNode else {
            debugPrint("there are no node!")
            return
        }
        guard let frame = sceneView.session.currentFrame else { return }
        let transform = SCNMatrix4(frame.camera.transform)
//        arrowNode.position = SCNVector3(0, 0, -0.5)
        arrowNode.position = SCNVector3(transform.m41,
                                        transform.m42,
                                        transform.m43 - 0.5)
        arrowNode.scale = SCNVector3(0.3, 0.3, 0.3)
        arrowNode.eulerAngles = SCNVector3(0, course, 0)
        sceneView.scene.rootNode.addChildNode(arrowNode)
    }
    
    func deleteArrow() {
        DispatchQueue.main.async {
            self.arrowNode?.removeFromParentNode()
        }
    }
    
    func loadArrowModel() {
        guard let arrowScene = SCNScene(named: "art.scnassets/arrow.scn") else {
            print("couldn't fetch a scene")
            return
        }
        arrowNode = arrowScene.rootNode.childNode(withName: "Arrow", recursively: false)
//        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.green
//        arrowNode?.geometry?.materials = [material]
    }
    
    func createArrowModel() -> SCNNode {
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
        
        let arrowNode = SCNNode(geometry: arrowGeometry)
        return arrowNode
    }
}
