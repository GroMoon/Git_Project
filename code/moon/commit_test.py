import sys
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QHBoxLayout, QPushButton, QLineEdit


class Calculator(QWidget):
    def __init__(self):
        super().__init__()

        self.setWindowTitle("Calculator")

        self.layout = QVBoxLayout()

        self.display = QLineEdit()
        self.display.setReadOnly(True)
        self.layout.addWidget(self.display)

        buttons_layout = [
            ['7', '8', '9', '/'],
            ['4', '5', '6', '*'],
            ['1', '2', '3', '-'],
            ['C', '0', '=', '+']
        ]

        for row in buttons_layout:
            h_layout = QHBoxLayout()
            for button_text in row:
                button = QPushButton(button_text)
                button.clicked.connect(self.on_button_clicked)
                h_layout.addWidget(button)
            self.layout.addLayout(h_layout)

        self.setLayout(self.layout)

    def on_button_clicked(self):
        button = self.sender()
        button_text = button.text()
        current_text = self.display.text()

        if button_text == 'C':
            self.display.clear()
        elif button_text == '=':
            try:
                result = str(eval(current_text))
                self.display.setText(result)
            except Exception as e:
                self.display.setText("Error")
        else:
            self.display.setText(current_text + button_text)


if __name__ == "__main__":
    app = QApplication(sys.argv)
    calculator = Calculator()
    calculator.show()
    sys.exit(app.exec_())