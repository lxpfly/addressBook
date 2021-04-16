//
//  ViewController.swift
//  AddressBookDemo
//
//  Created by 廖湘鹏 on 2021/4/15.
//

import UIKit
import Contacts

class Contacter:NSObject {
    @objc var name = ""
    @objc var phone = ""
    
    @objc func getName() -> String {
        return self.name
    }
}

class ViewController: UIViewController {
    
    var tableView:UITableView!
    let identifier = "Cell"
    var contactesArray:[Contacter] = Array() //存放通讯录数据
    var sortContactesArray:[Array<Contacter>] = Array() //排序后的通讯录数据

    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.requestContactAuthorAfterSystem()
    }
    
    func setupUI() {
        
        self.tableView = UITableView.init(frame: self.view.bounds, style: .plain)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView.init()
        self.tableView.register(UITableViewCell.classForCoder(), forCellReuseIdentifier: identifier)
        self.view.addSubview(self.tableView)
    }
    
    //查看通讯录权限
    func requestContactAuthorAfterSystem() {
        
        let status = CNContactStore .authorizationStatus(for: .contacts)
        if status == .notDetermined {
            //用户还没有就应用程序是否可以访问联系人数据做出选择。
            //请求弹窗选择
            let store = CNContactStore.init()
            store .requestAccess(for: .contacts) { (granted, error) in
                if (error != nil) {
                   print("授权失败")
                }else {
                    //授权成功，访问数据
                    DispatchQueue.main.async {
                        self .loadData()
                    }
                }
            }
        }else if status == .restricted {
            //用户没有权限，家长控制这些导致用户没有访问权限
        }else if status == .denied {
            //用户拒绝访问，引导用户打开通讯录权限
        }else if status == .authorized {
            //用户已同意访问，访问数据
            self.loadData()
        }
    }

    //读取通讯录数据
    func loadData() {
        
        /*
         CNContactGivenNameKey联系人的名字
         CNContactFamilyNameKey联系人的姓氏
         CNContactPhoneNumbersKey电话号码
         */
        let keysToFetch = [CNContactGivenNameKey as CNKeyDescriptor,CNContactFamilyNameKey as CNKeyDescriptor,CNContactPhoneNumbersKey as CNKeyDescriptor]
        let fetchRequest = CNContactFetchRequest(keysToFetch: keysToFetch)
        let contactStore = CNContactStore.init()
        
        try?contactStore.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) in
            
            //姓名
            let name = contact.familyName + contact.givenName
            //电话
            let phoneNumbers = contact.phoneNumbers
            for labelValue in phoneNumbers {
                
                let contacter = Contacter.init()
                var phoneNumber = labelValue.value.stringValue
                //对电话号码的数据进行整理
                phoneNumber = phoneNumber.replacingOccurrences(of: "+86", with: "")
                phoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
                phoneNumber = phoneNumber.replacingOccurrences(of: "-", with: "")
                phoneNumber = phoneNumber.replacingOccurrences(of: "(", with: "")
                phoneNumber = phoneNumber.replacingOccurrences(of: ")", with: "")
                phoneNumber = phoneNumber.replacingOccurrences(of: " ", with: "")
                print("姓名=\(name), 电话号码是=\(phoneNumber)")
                contacter.name = name
                contacter.phone = phoneNumber
                self.contactesArray.append(contacter)
                
            }
        })

        self.sortContactesArray = SortTool.sortObjectsAccordingToInitial(contactesArray: self.contactesArray)
        self.tableView.reloadData()
    }

}

extension ViewController:UITableViewDelegate,UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return self.sortContactesArray.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return self.sortContactesArray[section].count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier,for: indexPath)
        cell.textLabel?.text = self.sortContactesArray[indexPath.section][indexPath.row].name+"  "+self.sortContactesArray[indexPath.section][indexPath.row].phone
        return cell
    }
}

//排序
class SortTool: NSObject {
    
    class func sortObjectsAccordingToInitial(contactesArray:Array<Contacter>) -> Array<Array<Contacter>> {
        
        // 初始化UILocalizedIndexedCollation
        let collation = UILocalizedIndexedCollation.current()
        //得出collation索引的数量，这里是27个（26个字母和1个#）
        let sectionTitlesCount = collation.sectionTitles.count
        //初始化一个数组newSectionsArray用来存放最终的数据，我们最终要得到的数据模型应该形如[[以A开头的数据数组], [以B开头的数据数组], [以C开头的数据数组], ... [以#(其它)开头的数据数组]]
        var newSectionsArray:[Array<Contacter>] = Array.init()
        //初始化27个空数组加入newSectionsArray
        for _ in 0..<sectionTitlesCount {
            let array:[Contacter] = Array.init()
            newSectionsArray.append(array)
        }
        
        //将每个名字分到某个section下
        /*
         - (NSInteger)sectionForObject:(id)object collationStringSelector:(SEL)selector;
         // 返回将包含该对象的section的索引
         // 选择器不能接受任何参数并返回一个NSString对像
         */
        //遍历数组，YXAddressBookModel
        for contacter in contactesArray {
            //获取name属性的值所在的位置，比如"林丹"，首字母是L，在A~Z中排第11（第一位是0），sectionNumber就为11
            let sectionNumber = collation.section(for: contacter, collationStringSelector: #selector(contacter.getName))
            //把name为“林丹”的p加入newSectionsArray中的第11个数组中去
            var array = newSectionsArray[sectionNumber]
            array.append(contacter)
            newSectionsArray[sectionNumber] = array
        }
        
        //对每个section中的数组按照name属性排序
        for index in 0..<sectionTitlesCount {
            let personArrayForSection = newSectionsArray[index]
            let sortedPersonArrayForSection:[Contacter] = collation.sortedArray(from: personArrayForSection, collationStringSelector: #selector(getter: Contacter.name)) as! [Contacter]
            newSectionsArray[index] = sortedPersonArrayForSection
        }
        
        //最后返回的应该是一个装有27个数组的数组对象
        return newSectionsArray
    }
}
