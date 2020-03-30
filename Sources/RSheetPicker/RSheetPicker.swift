
import UIKit

fileprivate var sheetWindow: UIWindow?

// MARK: - sheet view basic
class RBasicSheetPicker {
    
    private(set) lazy var vcSheet: RSheetViewController = {
        let root = RSheetViewController()
        root.view.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 0.5)
        return root
    }()
    
    
    init(_ title: String) {
        self.vcSheet.title = title
        sheetWindow = UIWindow(frame: UIScreen.main.bounds)
        sheetWindow?.rootViewController = self.vcSheet
    }
    
    func done(action: ((Any) -> Void)?) -> Self {
        self.vcSheet.doneAction = action
        return self
    }
    
    func cancel(action: (() -> Void)?) -> Self {
        self.vcSheet.cancelAction = action
        return self
    }
    
    func show() {
        sheetWindow?.isHidden = false
    }
}

// MARK: - 一般選單
class RSheetPicker: RBasicSheetPicker {
    
    private override init(_ title: String) {
        super.init(title)
    }
    
    convenience init(_ title: String, data: [Any], selection: Any? = nil) {
        self.init(title)
        
        if data.allSatisfy({ $0 is Array<Any> }) {
            var defaultSelect: [Int]?
            if let select = selection as? [Int], select.count < data.count {
                defaultSelect = select
            }
            self.vcSheet.sheetType = .normal(model: .array(data: data), select: defaultSelect)
        } else {
            var defaultSelect: Int?
            if let select = selection as? Int, select < data.count {
                defaultSelect = select
            }
            self.vcSheet.sheetType = .normal(model: .none(data: data), select: defaultSelect)
        }
    }
}
// MARK: - 一般選單 選單資料連動
class RGearingSheetPicker: RBasicSheetPicker {
    private override init(_ title: String) {
        super.init(title)
    }
    
    convenience init(_ title: String, data: Dictionary<String, Any>, selection: Any? = nil) {
        self.init(title)
        
        let array = data.compactMap({ GearingSheetData(title: $0.key, child: $0.value) })
        let model: RSheetViewController.SheetType.dataType = .dictionary(data: array)
        var defaultSelect: [Int]?
        if let select = selection as? [Int], select.count < model.count {
            defaultSelect = select
        }
        self.vcSheet.sheetType = .normal(model: model, select: defaultSelect)
    }
    
    convenience init(_ title: String, data: Dictionary<Int, Any>, selection: Any? = nil) {
        self.init(title)
        
        let array = data.compactMap({ GearingSheetData(title: "\($0.key)", child: $0.value) })
        let model: RSheetViewController.SheetType.dataType = .dictionary(data: array)
        var defaultSelect: [Int]?
        if let select = selection as? [Int], select.count < model.count {
            defaultSelect = select
        }
        self.vcSheet.sheetType = .normal(model: model, select: defaultSelect)
    }
}
// MARK: - 日期選單
class RSheetDateTimePicker: RBasicSheetPicker {
    
    private override init(_ title: String) {
        super.init(title)
    }
    
    convenience init(_ title: String, model: UIDatePicker.Mode, defaultSection: Date) {
        self.init(title)
        self.vcSheet.sheetType = .date(model: model, default: defaultSection)
    }
}

// MARK: - picker view controller
class RSheetViewController: UIViewController {
    
    enum SheetType {
        case date(model: UIDatePicker.Mode, default: Date)
        case normal(model: dataType, select: Any?)
        
        var count: Int {
            switch self {
            case .date:
                return 0
            case .normal(let model, _):
                return model.count
            }
        }
        
        enum dataType {
            case array(data: [Any])
            case dictionary(data: [GearingSheetData])
            case none(data: [Any])
            
            var count: Int {
                switch self {
                case .none:
                    return 1
                case .array(let data):
                    return data.count
                case .dictionary(let data):
                    var hierarchy: Int = data.first?.hierarchy ?? 0
                    data.forEach { (item) in
                        let temp = item.hierarchy
                        if hierarchy > temp {
                            hierarchy = temp
                        }
                    }
                    return hierarchy
                }
            }
        }
    }
    
    var sheetType: SheetType = .normal(model: .none(data: []), select: nil)
    
    lazy private var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        return picker
    }()
    
    lazy private var normalPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()
    
    private lazy var viewSheet: UIView = {
        return self.createSheet()
    }()
    var doneAction: ((Any) -> Void)?
    var cancelAction: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch self.sheetType {
        case .date(let model, let defaultSelect):
            self.datePicker.datePickerMode = model
            self.datePicker.date = defaultSelect
            self.viewSheet.addSubview(self.datePicker)
            self.datePicker.translatesAutoresizingMaskIntoConstraints = false
            self.datePicker.topAnchor.constraint(equalTo: viewSheet.topAnchor, constant: 45).isActive = true
            self.datePicker.leftAnchor.constraint(equalTo: viewSheet.leftAnchor, constant: 0).isActive = true
            self.datePicker.rightAnchor.constraint(equalTo: viewSheet.rightAnchor, constant: 0).isActive = true
            self.datePicker.bottomAnchor.constraint(equalTo: viewSheet.bottomAnchor, constant: 0).isActive = true
        case .normal(let model, let select):
            self.viewSheet.addSubview(self.normalPicker)
            self.normalPicker.translatesAutoresizingMaskIntoConstraints = false
            self.normalPicker.topAnchor.constraint(equalTo: viewSheet.topAnchor, constant: 45).isActive = true
            self.normalPicker.leftAnchor.constraint(equalTo: viewSheet.leftAnchor, constant: 0).isActive = true
            self.normalPicker.rightAnchor.constraint(equalTo: viewSheet.rightAnchor, constant: 0).isActive = true
            self.normalPicker.bottomAnchor.constraint(equalTo: viewSheet.bottomAnchor, constant: 0).isActive = true
            switch model {
            case .array(let data):
                guard let rowArray = select as? [Int], let dataArray = data as? [[Any]] else { return }
                dataArray.enumerated().forEach { (item) in
                    if rowArray.count > item.offset {
                        let value = rowArray[item.offset]
                        if value < item.element.count {
                            self.normalPicker.selectRow(value, inComponent: item.offset, animated: false)
                        }
                    }
                }
            case .dictionary(let data):
                guard let rowArray = select as? [Int], rowArray.count <= model.count else { return }
                var array: [GearingSheetData] = data
                (0..<model.count).forEach { hier in
                    let row = rowArray[hier]
                    if row < array.count {
                        self.normalPicker.selectRow(row, inComponent: hier, animated: false)
                        array = array[row].childArray ?? []
                    } else {
                        array = array.first?.childArray ?? []
                    }
                }
            case .none(let data):
                guard let row = select as? Int, row < data.count else { return }
                self.normalPicker.selectRow(row, inComponent: 0, animated: false)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.25) {
            self.viewSheet.frame.origin = CGPoint(x: 0, y: UIScreen.main.bounds.height - self.viewSheet.bounds.height)
        }
    }
    
    // FIXME: - create sheet view
    private func createSheet() -> UIView {
        let bounds = UIScreen.main.bounds
        
        let viewSheet = UIView(frame: CGRect(x: 0, y: bounds.height, width: bounds.width, height: 350))
        viewSheet.backgroundColor = .white
        
        viewSheet.addSubview(self.createToolBar())
        
        viewSheet.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1).cgColor
        viewSheet.layer.shadowOffset = CGSize(width: 0, height: 0)
        viewSheet.layer.shadowOpacity = 0.8
        viewSheet.layer.masksToBounds = false
        
        self.view.addSubview(viewSheet)
        
        return viewSheet
    }
    // FIXME: - cancel action
    @objc private func cancel() {
        self.hiddenSheetView {
            self.cancelAction?()
        }
    }
    // FIXME: - done action
    @objc private func done() {
        self.hiddenSheetView {
            switch self.sheetType {
            case .normal(let model, _):
                switch model {
                case .array(let data):
                    var array: [Any] = []
                    data.enumerated().forEach { (item) in
                        if let child = item.element as? [Any] {
                            let value = child[self.normalPicker.selectedRow(inComponent: item.offset)]
                            array.append(value)
                        }
                    }
                    self.doneAction?(array)
                case .dictionary(let data):
                    var array: [Any] = []
                    var item: GearingSheetData?
                    (0..<self.sheetType.count).forEach { component in
                        let row = self.normalPicker.selectedRow(inComponent: component)
                        item = item?.childArray?[row] ?? data[row]
                        array.append(item?.title ?? "")
                    }
                    self.doneAction?(array)
                case .none(let data):
                    self.doneAction?(data[self.normalPicker.selectedRow(inComponent: 0)])
                }
            case .date(let model, _):
                switch model {
                case .countDownTimer:
                    self.doneAction?(self.datePicker.countDownDuration)
                default:
                    self.doneAction?(self.datePicker.date)
                }
            }
        }
    }
    
    // FIXME: - 關閉 sheet view
    private func hiddenSheetView(complete: @escaping (() -> Void)) {
        UIView.animate(withDuration: 0.25, animations: {
            self.viewSheet.frame.origin = CGPoint(x: 0, y: UIScreen.main.bounds.height)
        }) { (finished) in
            complete()
            sheetWindow?.rootViewController = nil
            sheetWindow?.resignKey()
            sheetWindow = nil
        }
    }
    
    // FIXME: - 建立 toolbar button
    private func createButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.frame = CGRect(x: 0, y: 0, width: 85, height: 45)
        btn.setTitle(title, for: .normal)
        btn.addTarget(nil, action: action, for: .touchUpInside)
        btn.widthAnchor.constraint(equalToConstant: 85).isActive = true
        return btn
    }
    // FIXME: - 建立 toolbar
    private func createToolBar() -> UIToolbar {
        
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 45))
        
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel))
        
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.done))
        
        let lbTitle = UILabel(frame: .zero)
        lbTitle.text = self.title
        lbTitle.sizeToFit()
        
        let barTitle = UIBarButtonItem(customView: lbTitle)
        
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let inset = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        inset.width = 5
        
        toolBar.setItems([inset, cancel, space, barTitle, space, done, inset], animated: false)
        return toolBar
    }
}
extension RSheetViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return self.sheetType.count
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch self.sheetType {
        case .date:
            return 0
        case .normal(let model, _):
            switch model {
            case .array(let data):
                return (data[component] as? [Any])?.count ?? 0
            case .dictionary(let data):
                var count = data.count
                var item: GearingSheetData?
                (0..<component).forEach { selectRow in
                    let row = pickerView.selectedRow(inComponent: selectRow)
                    item = item?.childArray?[row] ?? data[row]
                    count = item?.childArray?.count ?? 0
                }
                return count
            case .none(let data):
                return data.count
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch self.sheetType {
        case .date:
            return ""
        case .normal(let model, _):
            switch model {
            case .array(let data):
                guard let array = data[component] as? [Any] else { return "" }
                return "\(array[row])"
            case .dictionary(let data):
                var items: [GearingSheetData]? = data
                (0..<component).forEach { selectRow in
                    let select = pickerView.selectedRow(inComponent: selectRow)
                    items = items?[select].childArray
                }
                return items?[row].title ?? ""
            case .none(let data):
                return "\(data[row])"
            }
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch self.sheetType {
        case .normal(let model, _):
            switch model {
            case .dictionary:
                if component < self.sheetType.count - 1 {
                    pickerView.reloadComponent(component + 1)
                }
            default:
                break
            }
        default:
            break
        }
    }
}
