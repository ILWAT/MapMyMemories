//
//  HomeViewController.swift
//  MapMyMemories
//
//  Created by 문정호 on 2023/09/26.
//


import UIKit
import CoreLocation
import CoreLocationUI
import MapKit
import Floaty
import RealmSwift

final class HomeViewController: BaseViewController{
    //MARK: - Properties
    let mainView = HomeView()
    
    let locationManager: CLLocationManager = CLLocationManager()
    
    var memoryData: Results<MemoryDB>?
    
    var displayCellData: [MemoryDB] = []{
        didSet{
            mainView.collectionView.reloadData()
        }
    }
    
    
    
    //MARK: - LifeCycle
    override func loadView() {
        view = mainView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(#function)
        setAnnotation()
    }
    
    //MARK: - Configure
    override func configure() {
        //delegate 채택
        locationManager.delegate = self
        mainView.mapView.delegate = self
        mainView.collectionView.delegate = self
        mainView.collectionView.dataSource = self
        
        //floating Button 추가
        mainView.floatingButton.addItem("기록하기", icon: UIImage(systemName: "pencil.line")) { item in
            self.navigationController?.pushViewController(WriteViewController(), animated: true)
        }
        
        //CLLocationButton 액션 추가, AnnotationView 등록
        mainView.locationButton.addTarget(self, action: #selector(tappedLocationButton), for: .touchUpInside)
        mainView.mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.identifier)
        
        
        checkDeviceAuthorization()
    }
    
    
    //MARK: - SetNavigation
    override func setNavigation() {
        self.navigationController?.navigationItem.largeTitleDisplayMode = .always
        self.title = "내 추억 장소"
    }
    
    //MARK: - Action
    @objc func tappedLocationButton(_ sender: CLLocationButton){
        self.locationManager.startUpdatingLocation()
    }
    
    //MARK: - Helper
    
    func checkDeviceAuthorization(){
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled(){
                let status: CLAuthorizationStatus = self.locationManager.authorizationStatus
                
                DispatchQueue.main.async {
                    self.checkUserAuthorization(authorization: status)
                }
            }
        }
    }
    
    func checkUserAuthorization(authorization: CLAuthorizationStatus){
        switch authorization {
        case .notDetermined:
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.requestWhenInUseAuthorization()
        case .restricted:
            showAuthorizationAlert()
            setUserLocation()
        case .denied:
            showAuthorizationAlert()
            setUserLocation()
        case .authorizedAlways:
            self.locationManager.startUpdatingLocation()
        case .authorizedWhenInUse:
            self.locationManager.startUpdatingLocation()
        case .authorized:
            self.locationManager.startUpdatingLocation()
        @unknown default:
            print("UnknownLocationAuthorization")
        }
    }
    
    func showAuthorizationAlert(){
        let alert = UIAlertController(title: "위치 권한 허용이 필요합니다.", message: "위치 서비스를 사용할 수 없습니다.\n기기의 '설정>개인정보 보호'에서 위치 서비스를 켜주세요.", preferredStyle: .alert)
        
        let goSetting = UIAlertAction(title: "설정 이동", style: .default) { action in
            if let settingURL = URL(string: UIApplication.openSettingsURLString){
                UIApplication.shared.open(settingURL)
            }
        }
        
        let cancel = UIAlertAction(title: "취소", style: .cancel)
        
        [goSetting, cancel].forEach { action in
            alert.addAction(action)
        }
        
        self.present(alert, animated: true)
    }
    
    func setUserLocation(_ coordinate: CLLocationCoordinate2D? = nil){
        let region: MKCoordinateRegion
        let defaultMeter: CLLocationDistance = 500
        
        if let coordinate {
            region = MKCoordinateRegion(center: coordinate, latitudinalMeters: defaultMeter, longitudinalMeters: defaultMeter)
        } else {
            //서울 시청 기본 위치 : 37.566713, 126.978428
            let defaultLocation = CLLocationCoordinate2D(latitude: 37.566713, longitude: 126.978428)
            
            region = MKCoordinateRegion(center: defaultLocation, latitudinalMeters: defaultMeter, longitudinalMeters: defaultMeter)
        }
        
        mainView.mapView.setRegion(region, animated: true)
        
    }
    
    func setAnnotation(){
        RealmManager.shared.readAllRecord(type: MemoryDB.self) { results in
            self.memoryData = results
        }
        guard let memoryData else {
            print("none MemoryData")
            return}
        
        for element in memoryData{
            guard let lat = element.address?.lat, let long = element.address?.long else {  
                print("failed load Address")
                return }
            
            let annotation = MemoryAnnotation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long), memoryData: element)
    
            mainView.mapView.addAnnotation(annotation)
        }
        
        
    }
}

extension HomeViewController: CLLocationManagerDelegate, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource{
    
    //MARK: - CLLocationMangerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last?.coordinate else {return}
        setUserLocation(location)
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        self.makeToastMessage(errorType: .failedloadLocation)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkDeviceAuthorization()
    }
    
    //MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.identifier, for: annotation) as? MKMarkerAnnotationView else {
            print("early exit MKMarker upCasting")
            return MKAnnotationView(annotation: annotation, reuseIdentifier: MKAnnotationView.identifier) }
        annotationView.canShowCallout = false
        
        annotationView.glyphImage = UIImage(systemName: "star.fill")
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        guard let annotation = annotation as? MemoryAnnotation else { 
            print("early exit Annotation")
            return }
        
        if let lat = annotation.memoryData.address?.lat, let long = annotation.memoryData.address?.long {
            mainView.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), latitudinalMeters: 500, longitudinalMeters: 500), animated: true)
        }
       
        
        //클릭시 간략한 정보를 보이기
        mainView.collectionView.isHidden = false
        displayCellData = [annotation.memoryData]
        
    }
    
    func mapView(_ mapView: MKMapView, didDeselect annotation: MKAnnotation) {
        mainView.collectionView.isHidden = true
    }
    
//    func mapView(_ mapView: MKMapView, clusterAnnotationForMemberAnnotations memberAnnotations: [MKAnnotation]) -> MKClusterAnnotation {
//        <#code#>
//    }
    //MARK: - CollectionView Delegate & DataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayCellData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SummaryCollectionViewCell.identifier, for: indexPath) as? SummaryCollectionViewCell else {return UICollectionViewCell()}
        
        cell.setCellUI(image: nil, title: displayCellData[indexPath.item].title, location: displayCellData[indexPath.item].address?.addressName ?? "데이터 로드에 실패했습니다.")
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItem")
    }
}
