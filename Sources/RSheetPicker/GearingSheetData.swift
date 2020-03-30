//
//  File.swift
//  
//
//  Created by Ray on 2020/3/30.
//

import Foundation

// MARK: - Dictionary 轉換自訂格式
struct GearingSheetData {
    var title: String
    var childArray: [GearingSheetData]?
    var hierarchy: Int = 1
    
    
    init(title: String, child: Any? = nil) {
        self.title = title
        
        if let dic = child as? Dictionary<String, Any> {
            self.childArray = dic.compactMap { (item) -> GearingSheetData? in
                let gearing = GearingSheetData(title: item.key, child: item.value)
                self.hierarchy = gearing.getHierarchy(with: self.hierarchy)
                return gearing
            }
        } else if let dic = child as? Dictionary<Int, Any> {
            self.childArray = dic.compactMap { (item) -> GearingSheetData? in
                let gearing = GearingSheetData(title: "\(item.key)", child: item.value)
                self.hierarchy = gearing.getHierarchy(with: self.hierarchy)
                return gearing
            }
        } else if let array = child as? [Any] {
            self.childArray = array.compactMap({ GearingSheetData(title: "\($0)") })
            self.hierarchy = self.hierarchy + 1
        } else if let value = child {
            self.childArray = [GearingSheetData(title: "\(value)")]
            self.hierarchy = self.hierarchy + 1
        }
    }
    
    @discardableResult
    func getHierarchy(with hierarchy: Int) -> Int {
        guard self.childArray != nil else { return hierarchy }
        return hierarchy + 1
    }
}
