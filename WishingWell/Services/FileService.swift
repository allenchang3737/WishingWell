//
//  FileService.swift
//  WishingWell
//
//  Created by Lun Yu Chang on 2024/3/14.
//

import Foundation
import Alamofire
import SwiftyJSON
import Kingfisher

class FileService {
    static let shared: FileService = FileService()
    
    private init() {
        print("FileService init..")
    }
    
    //MARK: Image
    /// Upload Image: save object to DB table
    /// Parameters
    /// - `file`:  File Object
    /// - `image`:  image data
    func uploadImage(file: File, image: UIImage, completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("jpegData fail...")
            return
        }
        
        let path = APIManager().getBaseURL() + "/fc/file"
        let params: [String : Any] = [File.InfoKey.customId: file.customId,
                                      File.InfoKey.type: file.type,
                                      File.InfoKey.orderNo: file.orderNo ?? 0]
        
        AF.upload(multipartFormData: { multipart in
            multipart.append(data,
                             withName: "file",
                             fileName: "\(file.fileName).jpeg",
                             mimeType: "image/jpeg")
            //Append params
            for (key, value) in params {
                if let temp = value as? String,
                   let data = temp.data(using: .utf8) {
                    multipart.append(data, withName: key)
                }
                if let temp = value as? Int,
                   let data = "\(temp)".data(using: .utf8) {
                    multipart.append(data, withName: key)
                }
            }
        }, to: path, headers: APIManager().headers).uploadProgress(queue: .main, closure: { progress in
            print("uploadImage Progress: \(progress.fractionCompleted)")
        })
        .response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler()

                }catch {
                    print("uploadImage JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("uploadImage Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Download Image
    /// Parameters
    /// - `fileId`:  File PK
    private func downloadImage(fileId: Int, completionHandler: @escaping (UIImage) -> ()) {
#if DEV
        DispatchQueue.main.async {
            guard let image = UIImage(named: "fileId_\(fileId)") else { return }
            completionHandler(image)
        }
#else
        let path = APIManager().getBaseURL() + "/fc/file"
        let params: Parameters = [File.InfoKey.fileId: fileId]
        
        AF.request(path, method: .get, parameters: params).response { response in
            guard let data = response.data,
                  let image = UIImage(data: data) else {
                print("downloadImage Fail: \(LocalizedError.self)")
                return
            }
            
            ImageCache.default.store(image, forKey: "\(fileId)")
            completionHandler(image)
        }
#endif
    }
    
    /// Get Image
    /// Parameters
    /// - `fileId`: File PK
    func getImage(fileId: Int, completionHandler: @escaping (UIImage) -> ()) {
#if DEV
        guard let image = UIImage(named: "fileId_\(fileId)") else { return }
        DispatchQueue.main.async {
            completionHandler(image)
        }
#else
        ImageCache.default.retrieveImage(forKey: "\(fileId)") { result in
            switch result {
            case .success(let value):
                if let image = value.image {
                    completionHandler(image)
                    
                }else {
                    self.downloadImage(fileId: fileId) { image in
                        completionHandler(image)
                    }
                }
                
            case .failure(let error):
                print("retrieveImage Error: \(error)")
            }
        }
#endif
    }
    
    //MARK: Image URL
    /// Upload Image: save image to "http://your-domain.com/images/[FileName]"
    /// Parameters
    /// - `fileName`: path  file name
    /// - `image`:  image data
    func uploadImage(fileName: String, image: UIImage, completionHandler: @escaping (String) -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler("https://upload.wikimedia.org/wikipedia/commons/a/ab/Apple-logo.png")
        }
#else
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("jpegData fail")
            return
        }
        
        let path = APIManager().getBaseURL() + "/fc/image"
        AF.upload(multipartFormData: { multipart in
            multipart.append(data,
                             withName: "image",
                             fileName: "\(fileName).jpeg",
                             mimeType: "image/jpeg")
            
        }, to: path, headers: APIManager().headers).uploadProgress(queue: .main, closure: { progress in
            print("uploadImage Progress: \(progress.fractionCompleted)")
        })
        .response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseResultRs<UploadImageRs>.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue,
                          let result = store.result else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler(result.imageUrl)

                }catch {
                    print("uploadImage JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("uploadImage Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    /// Download Image
    /// Parameters
    /// - `url`:  image path
    private func downloadImage(url: String, completionHandler: @escaping (UIImage) -> ()) {
#if DEV
        DispatchQueue.main.async {
            guard let image = UIImage(named: "fileId_999") else { return }
            completionHandler(image)
        }
#else
        AF.request(url, method: .get).response { response in
            guard let data = response.data,
                  let image = UIImage(data: data) else {
                print("downloadImage Fail: \(LocalizedError.self)")
                return
            }
            
            ImageCache.default.store(image, forKey: url)
            completionHandler(image)
        }
#endif
    }
    
    /// Get Image
    /// Parameters
    /// - `url`: image path
    func getImage(url: String, completionHandler: @escaping (UIImage) -> ()) {
#if DEV
        DispatchQueue.main.async {
            guard let image = UIImage(named: "fileId_999") else { return }
            completionHandler(image)
        }
#else
        ImageCache.default.retrieveImage(forKey: url) { result in
            switch result {
            case .success(let value):
                if let image = value.image {
                    completionHandler(image)
                    
                }else {
                    self.downloadImage(url: url) { image in
                        completionHandler(image)
                    }
                }
                
            case .failure(let error):
                print("retrieveImage Error: \(error)")
            }
        }
#endif
    }
    
    //MARK: Image Array
    /// Upload Images: save object to DB table
    /// Parameters
    /// - `file`:  File Object
    /// - `images`:  image array
    func uploadImages(file: File, images: [UIImage], completionHandler: @escaping () -> ()) {
#if DEV
        DispatchQueue.main.async {
            completionHandler()
        }
#else
        let path = APIManager().getBaseURL() + "/fc/files"
        let params: [String : Any] = [File.InfoKey.customId: file.customId,
                                      File.InfoKey.type: file.type]
        
        AF.upload(multipartFormData: { multipart in
            for (index, image) in images.enumerated() {
                guard let data = image.jpegData(compressionQuality: 0.8) else {
                    print("jpegData fail")
                    return
                }
                multipart.append(data,
                                 withName: "files",
                                 fileName: "\(file.fileName)_\(index).jpeg",
                                 mimeType: "image/jpeg")
            }
            
            //Append params
            for (key, value) in params {
                if let temp = value as? String,
                   let data = temp.data(using: .utf8) {
                    multipart.append(data, withName: key)
                }
                if let temp = value as? Int,
                   let data = "\(temp)".data(using: .utf8) {
                    multipart.append(data, withName: key)
                }
            }
        }, to: path, headers: APIManager().headers).uploadProgress(queue: .main, closure: { progress in
            print("uploadImage Progress: \(progress.fractionCompleted)")
        })
        .response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler()

                }catch {
                    print("uploadImages JSON Decoded Error: \(error.localizedDescription)")
                }

            case .failure(let error):
                print("uploadImages Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
    
    func deleteFiles(fileIds: [Int], completionHandler: (() -> ())? = nil) {
#if DEV
        DispatchQueue.main.async {
            completionHandler?()
        }
#else
        guard !fileIds.isEmpty else { return }
        let path = APIManager().getBaseURL() + "/fc/files"
        let params: Parameters = ["fileIds": fileIds]
        
        let encoding = URLEncoding(destination: .queryString, arrayEncoding: .noBrackets, boolEncoding: .literal)
        AF.request(path, method: .delete, parameters: params, encoding: encoding, headers: APIManager().headers).response { response in
            switch response.result {
            case .success:
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data).rawData()
                    let decoder = JSONDecoder()
                    let store = try decoder.decode(BaseRs.self, from: json)
                    guard store.status == BaseStatus.SUCCESS.rawValue else {
                        NotificationCenter.default.post(name: .showAlertNotification, object: nil, userInfo: [MyKey.UserInfo.message: store.message])
                        return
                    }
                    completionHandler?()
                    
                }catch {
                    print("deleteFiles JSON Decoded Error: \(error.localizedDescription)")
                }
                
            case .failure(let error):
                print("deleteFiles Error: \(response.response?.statusCode ?? 0) - \(error)")
            }
        }
#endif
    }
}
