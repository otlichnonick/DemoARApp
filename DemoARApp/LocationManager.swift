//
//  LocationManager.swift
//  DemoARApp
//
//  Created by Anton on 15.09.2021.
//

import Foundation
import CoreLocation
import Combine

protocol LocationManagerDelegate {
    func locationManager(_ locationManager: LocationManager, didEnterRegionId regionId: String)
    func locationManager(_ locationManager: LocationManager, didExitRegionId regionId: String)
}

class LocationManager: NSObject, ObservableObject {
    enum GeofencingError: Error {
      case notAuthorized
      case notSupported
    }

    var locationManager: CLLocationManager
    var delegate: LocationManagerDelegate?
    var trackedLocation: CLLocationCoordinate2D?
    @Published var distance: Double = 0
    @Published var errorMessage = ""
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
    }
    
    func initialize() {
      locationManager.delegate = self
      locationManager.activityType = .otherNavigation
      locationManager.requestAlwaysAuthorization()
      locationManager.startUpdatingLocation()
    }
    
    func startMonitoring(location: CLLocationCoordinate2D) throws {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { throw GeofencingError.notSupported }
        
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            trackedLocation = location
        default:
            throw GeofencingError.notAuthorized
        }
    }
    
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        guard let trackedLocation = trackedLocation else { return }
        let location = CLLocation(latitude: trackedLocation.latitude, longitude: trackedLocation.longitude)
        distance = currentLocation.distance(from: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
      errorMessage = "Location manager failed with error: \(error.localizedDescription)"
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
      print("Authorization status changed to: \(status)")
    }
}
