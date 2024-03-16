import tkinter as tk

class Calculator:
    def __init__(self, master):
        self.master = master
        master.title("Calculator")

        self.entry = tk.Entry(master, width=20, borderwidth=5)
        self.entry.grid(row=0, column=0, columnspan=4, padx=10, pady=10)

        button_texts = [
            '7', '8', '9', '/',
            '4', '5', '6', '*',
            '1', '2', '3', '-',
            'C', '0', '=', '+'
        ]

        self.buttons = []
        for i, text in enumerate(button_texts):
            row = i // 4 + 1
            col = i % 4
            button = tk.Button(master, text=text, padx=20, pady=10, command=lambda t=text: self.on_button_click(t))
            button.grid(row=row, column=col, padx=5, pady=5)
            self.buttons.append(button)

    def on_button_click(self, text):
        current = self.entry.get()

        if text == 'C':
            self.entry.delete(0, tk.END)
        elif text == '=':
            try:
                result = str(eval(current))
                self.entry.delete(0, tk.END)
                self.entry.insert(0, result)
            except Exception as e:
                self.entry.delete(0, tk.END)
                self.entry.insert(0, "Error")
        else:
            self.entry.insert(tk.END, text)


if __name__ == "__main__":
    root = tk.Tk()
    calculator = Calculator(root)
    root.mainloop()