# 계산기 예제
class Calculator:
    def add(self, x, y):
        return x + y

    def subtract(self, x, y):
        return x - y

    def multiply(self, x, y):
        return x * y

    def divide(self, x, y):
        if y == 0:
            return "Error: Division by zero"
        else:
            return x / y

# 여기에 class 추가해서 사용 가능 : import 예시는 example.py에서 확인