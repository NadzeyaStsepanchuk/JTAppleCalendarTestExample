import UIKit
import JTAppleCalendar

class CalendarViewController: UIViewController {

    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var weekdaysStackView: UIStackView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var previousMonthButton: UIButton!
    @IBOutlet weak var nextMonthButton: UIButton!
    
    private lazy var calendar = Calendar.current
    private lazy var selectedDates: [Date] = []
    private lazy var maxDatesCount: Int? = nil
    private lazy var color = UIColor.blue
    private lazy var startDate = Date.today
    private lazy var endDate = self.startDate.append(years: 1)!
    private var firstSelectedDate: Date?
    private var lastSelectedDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        initWeekdaysStackView()
        initCalendarView()
    }
    
    @IBAction func previousMonth(_ sender: Any) {
        //BUG:
        self.calendarView.scrollToSegment(.previous)
        //FIX for iOS 10:
//        self.calendarView.scrollToSegment(.previous, triggerScrollToDateDelegate: false, animateScroll: true, extraAddedOffset: 0.0, completionHandler: {
//            self.calendarView.reloadData()
//        })
    }
    
    @IBAction func nextMonth(_ sender: Any) {
        self.calendarView.scrollToSegment(.next)
    }
    
}

extension CalendarViewController: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        let numberOfRows = 6
        let generateInDates: InDateCellGeneration = .forAllMonths
        let generateOutDates: OutDateCellGeneration = .tillEndOfGrid
        let hasStrictBoundaries = true
        var firstDayOfWeek: DaysOfWeek = .monday
        if self.calendar.firstWeekday == 1 {
            firstDayOfWeek = .sunday
        }
        
        let parameters = ConfigurationParameters(startDate: self.startDate,
                                                 endDate: self.endDate,
                                                 numberOfRows: numberOfRows,
                                                 calendar: self.calendar,
                                                 generateInDates: generateInDates,
                                                 generateOutDates: generateOutDates,
                                                 firstDayOfWeek: firstDayOfWeek,
                                                 hasStrictBoundaries: hasStrictBoundaries)
        return parameters
    }
    
    func calendar(_ calendar: JTAppleCalendarView, shouldSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) -> Bool {
        let result = date.compare(self.startDate)
        if result == .orderedAscending {
            return false
        }
        if let maxDatesCount = maxDatesCount, !calendarView.selectedDates.contains(date), calendarView.selectedDates.count == maxDatesCount {
            return false
        }
        return true
    }
    
    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        // This function should have the same code as the cellForItemAt function
        let cell = cell as! CustomJTAppleCell
        configureVisibleCell(cell: cell, cellState: cellState, date: date)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableCell(withReuseIdentifier: "CustomJTAppleCell", for: indexPath) as! CustomJTAppleCell
        cell.selectionColor = self.color
        configureVisibleCell(cell: cell, cellState: cellState, date: date)
        return cell
    }
    
    private func handleMultiSelection(date: Date) {
        if let firstSelectedDate = self.firstSelectedDate {
            self.calendarView.deselectAllDates(triggerSelectionDelegate: false)
            let result = date.compare(firstSelectedDate)
            if result == .orderedAscending {
                let lastSelectedDate = self.lastSelectedDate ?? firstSelectedDate
                self.firstSelectedDate = date
                self.calendarView.selectDates(from: date, to: lastSelectedDate, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
            } else if result == .orderedDescending {
                self.lastSelectedDate = date
                self.calendarView.selectDates(from: firstSelectedDate, to: date, triggerSelectionDelegate: false, keepSelectionIfMultiSelectionAllowed: true)
            }
        } else {
            self.firstSelectedDate = date
        }
    }
    
    private func handleMultiDeselection(date: Date) {
        if let firstSelectedDate = self.firstSelectedDate {
            if date == firstSelectedDate {
                self.calendarView.deselectAllDates(triggerSelectionDelegate: false)
                self.firstSelectedDate = nil
                self.lastSelectedDate = nil
            } else {
                handleMultiSelection(date: date)
            }
        }
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        handleCellConfiguration(cell: cell, cellState: cellState)
        handleMultiSelection(date: date)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        handleCellConfiguration(cell: cell, cellState: cellState)
        handleMultiDeselection(date: date)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        setupViewsOfCalendar(from: visibleDates)
    }
    
}

private extension CalendarViewController {
    
    func initWeekdaysStackView() {
        var index = self.calendar.firstWeekday - 1
        for view in weekdaysStackView.subviews as [UIView] {
            if let label = view as? UILabel {
                label.text = self.calendar.shortWeekdaySymbols[index]
                label.backgroundColor = self.color
                index = index + 1
            }
            if index == self.calendar.shortWeekdaySymbols.count {
                index = 0
            }
        }
    }
    
    func initCalendarView() {
        self.calendarView.allowsMultipleSelection = true
        self.calendarView.isRangeSelectionUsed = true
        self.calendarView.visibleDates {[unowned self] (visibleDates: DateSegmentInfo) in
            self.setupViewsOfCalendar(from: visibleDates)
        }
        self.calendarView.selectDates(self.selectedDates)
        let date = self.selectedDates.first ?? Date.today
        self.calendarView.scrollToDate(date, triggerScrollToDateDelegate: true, animateScroll: false, preferredScrollPosition: nil, extraAddedOffset: 0, completionHandler: nil)
    }
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        guard let date = visibleDates.monthDates.first?.date else {
            return
        }
        
        let month = self.calendar.dateComponents([.month], from: date).month!
        let monthName = DateFormatter().monthSymbols[(month - 1) % 12]
        let year = self.calendar.component(.year, from: date)
        self.monthLabel.text = monthName + " " + String(year)
        
        self.previousMonthButton.alpha = 1.0
        self.nextMonthButton.alpha = 1.0
        
        let calendar = self.calendar as NSCalendar
        let startDateComponents = calendar.components([.month, .year], from: self.startDate)
        let endDateComponents = calendar.components([.month, .year], from: self.endDate)
        
        if (month == startDateComponents.month && year == startDateComponents.year) {
            self.previousMonthButton.alpha = 0.0
        }
        else if (month == endDateComponents.month && year == endDateComponents.year) {
            self.nextMonthButton.alpha = 0.0
        }
    }
    
    func handleCellConfiguration(cell: JTAppleCell?, cellState: CellState) {
        handleCellTextColor(view: cell, cellState: cellState)
        handleCellSelection(view: cell, cellState: cellState)
    }
    
    func handleCellTextColor(view: JTAppleCell?, cellState: CellState) {
        guard let cell = view as? CustomJTAppleCell else {
            return
        }
        
        if cellState.dateBelongsTo == .thisMonth {
            cell.dayLabel.textColor = UIColor.black
        } else {
            cell.dayLabel.textColor = UIColor.darkGray
        }
    }
    
    func handleCellSelection(view: JTAppleCell?, cellState: CellState) {
        guard let cell = view as? CustomJTAppleCell else {
            return
        }
        
        cell.setSelected(cellState.isSelected)
    }
    
    func configureVisibleCell(cell: CustomJTAppleCell, cellState: CellState, date: Date) {
        cell.dayLabel.text = cellState.text
        let isToday = self.calendar.isDateInToday(date)
        cell.isToday = isToday
        handleCellConfiguration(cell: cell, cellState: cellState)
    }
    
}
