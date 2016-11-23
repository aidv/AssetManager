//  myViewController.swift
//  AssetManager Example
//
//  Created by Aid Vllasaliu on 2016-11-23.
//  Copyright © 2016 Aid Vllasaliu. All rights reserved.
//
//  License: GNU GPLv3

import Foundation
import Photos;


protocol assetManagerNotificationProtocol {
    func onAssetAssembled(asset: assetInfo)
    func onAssemblyComplete()
}


var assetManagerChunkSize: Int = 5000000
func assetManagerAssetCountChunks(asset: assetInfo) -> Int { return Int(ceilf(Float(asset.size) / Float(assetManagerChunkSize))) }

struct extractionResults {
    var status: String
    var chunkIndex = 0
    var assetInfo: assetInfo
    var data = Data()
}


class assetInfo{
    var id           = NSUUID().uuidString;
    var index        = Int()
    var fullpath     = String()
    var filename     = String()
    var size         = Int()
    var creationDate = Date()
    
    var dateTime = dateTimeBreakout()
    
    

    
    func extractData(chunkIndex: Int, chunkComplete: @escaping (extractionResults) -> Void, extractionComplete: @escaping (extractionResults) -> Void){
        
        DispatchQueue.global(qos: .background).async(execute: {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending:true)]
            let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: fetchOptions)
            
            var resourceArray: [PHAssetResource]  = PHAssetResource.assetResources(for: fetchResult[self.index])
            
            let arm: PHAssetResourceManager = PHAssetResourceManager.default()
            
            
            var bytesRead: Int = 0;
            var bytesReadBefore = 0;
            
            let startByte = assetManagerChunkSize * chunkIndex;
            
            var foundStartByte = false;
            
            var cancelServing = false;
            
            var startCut = 0;
            
            var results = extractionResults(status: "ok", chunkIndex: chunkIndex, assetInfo: self, data: Data())
            
            
            autoreleasepool {
                
                var ID: PHAssetResourceDataRequestID? = nil
                
                ID = arm.requestData(for: resourceArray[0], options: PHAssetResourceRequestOptions(),
                                     dataReceivedHandler:{(data: Data) -> Void in
                                        
                                        bytesReadBefore = bytesRead
                                        bytesRead += data.count
                                        
                                        
                                        
                                        if assetManagerChunkSize >= self.size {
                                            results.data.append(data);
                                            arm.cancelDataRequest(ID!) //Error occurs here!!!!!!
                                        } else {
                                            if bytesRead >= startByte {
                                                
                                                if foundStartByte == false {
                                                    if chunkIndex > 0 { startCut = startByte - bytesReadBefore}
                                                    foundStartByte = true;
                                                }
                                                
                                                if foundStartByte == true {
                                                    results.data.append(data)
                                                    
                                                    if data.count == 0 {
                                                        results.data = results.data.subdata(in: Range(uncheckedBounds: (lower: startCut, upper: results.data.count )))
                                                        cancelServing = true
                                                    }
                                                    
                                                    if bytesRead >= startByte + assetManagerChunkSize && results.data.count >= assetManagerChunkSize {
                                                        results.data = results.data.subdata(in: Range(uncheckedBounds: (lower: startCut, upper: startCut + assetManagerChunkSize)))
                                                        cancelServing = true;
                                                        
                                                    }
                                                }
                                            }
                                        }
                                        
                                        if cancelServing == true {
                                            chunkComplete(results)
                                            arm.cancelDataRequest(ID!) //Error occurs here!!!!!!
                                        }
                                        
                                        
                },
                                     
                                     completionHandler:{(error: Error?) -> Void in
                                        if error != nil { results.status = "error" }
                                        
                                        extractionComplete(results)
                }
                    
                )
            }
            
        }
        )}
    
}



class assetManager{
    var assets = [assetInfo]()
    private var assetsCount = 0
    
    var notificationReceiver: assetManagerNotificationProtocol? = nil

    private func assembleAsset(assetIndex: Int, assemblyComplete: @escaping (assetInfo) -> Void) {
        
        DispatchQueue.global(qos: .background).async(execute: {
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending:true)]
            let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: fetchOptions)

            var resourceArray: [PHAssetResource]  = PHAssetResource.assetResources(for: fetchResult[assetIndex])
            
            let arm: PHAssetResourceManager = PHAssetResourceManager.default()
            
            var dataSize: Int = 0
            
            arm.requestData(for: resourceArray[0], options: PHAssetResourceRequestOptions(),
                                dataReceivedHandler: {(assetData: Data) -> Void in dataSize += assetData.count; },
                                
                                completionHandler: {(error: Error?) -> Void in
                                    if error == nil {
                                        assemblyComplete(self.addAsset(assetIndex,
                                                                       aAssetPathFull: resourceArray[0].originalFilename,
                                                                       aAssetSize: dataSize,
                                                                       aAssetDate: fetchResult[assetIndex].creationDate!)
                                        )
                                    }
                                }
                )
        });
    }
    
    
    private func addAsset(_ aAssetIndex: Int, aAssetPathFull: String, aAssetSize: Int, aAssetDate: Date) -> assetInfo {
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy,MM,dd,HH,mm,ss"
        
        dateFormatter.dateFormat = "yyyy"
        let y: String = dateFormatter.string(from: aAssetDate)
        
        dateFormatter.dateFormat = "MM"
        let m = dateFormatter.string(from: aAssetDate)
        
        dateFormatter.dateFormat = "dd"
        let d = dateFormatter.string(from: aAssetDate)
        
        dateFormatter.dateFormat = "HH"
        let h = dateFormatter.string(from: aAssetDate)
        
        dateFormatter.dateFormat = "mm"
        let min = dateFormatter.string(from: aAssetDate)
        
        dateFormatter.dateFormat = "ss"
        let s = dateFormatter.string(from: aAssetDate)
        
        dateFormatter.dateFormat = "SSS"
        let ms = dateFormatter.string(from: aAssetDate)
        
        
        
        assets.append(assetInfo())
        let aI: assetInfo = assets.last!
        
        
        aI.index    = aAssetIndex;
        
        aI.fullpath = aAssetPathFull;
        aI.filename = aAssetPathFull;
        
        aI.size = aAssetSize;
        
        aI.dateTime.year   = Int(y)!
        aI.dateTime.month  = Int(m)!
        aI.dateTime.day    = Int(d)!
        aI.dateTime.hour   = Int(h)!
        aI.dateTime.minute = Int(min)!
        aI.dateTime.second = Int(s)!
        aI.dateTime.millisecond = Int(ms)!
        
        if self.notificationReceiver != nil { self.notificationReceiver!.onAssetAssembled(asset: assets.last!) }
        
        return assets.last!
    }
    
   
    
    private func triggerNext(triggerComplete: @escaping () -> Void){ assembleAsset(assetIndex: assets.count, assemblyComplete: { (asset: assetInfo) -> Void in triggerComplete() } )}
    
    private func checkAssemblyStatus() -> Bool { if assets.count < assetsCount - 1 { return false } else { return true } }
    
    private func iterateAssets(){ triggerNext(triggerComplete: { () -> Void in
            if self.checkAssemblyStatus() == false {
                self.iterateAssets()
            } else {
                if self.notificationReceiver != nil { self.notificationReceiver!.onAssemblyComplete() }
            }
        })
    }
    
    func assembleAssets(){
        assets.removeAll()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending:true)]
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: fetchOptions)

        assetsCount = fetchResult.count
        
        iterateAssets()
    }
    
    func count() -> Int{ return assets.count }
    
    func remove(_ index: Int){ assets.remove(at: index) }
    
    func asset(_ index: Int) -> assetInfo { return assets[index] }
    
    
    
}
