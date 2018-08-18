import JTAppleCalendar

class CustomJTAppleCell: JTAppleCell {
    
    @IBOutlet var dayLabel: UILabel!

    var selectionColor: UIColor?
    var isToday: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setSelected(false)
    }
    
    func setSelected(_ selected: Bool) {
        let selectionColor = self.selectionColor ?? UIColor.white
        if selected {
            self.backgroundColor = selectionColor.withAlphaComponent(0.2)
        } else {
            self.backgroundColor = UIColor.white
            self.layer.borderWidth = 0.5
            self.layer.borderColor = UIColor.darkGray.withAlphaComponent(0.2).cgColor
        }
        if self.isToday {
            self.layer.borderWidth = 2.0
            self.layer.borderColor = selectionColor.cgColor
        }
    }
    
}
