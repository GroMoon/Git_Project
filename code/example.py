# 이 파일은 예시 파일입니다. 연습용으로 사용하세요.

from common.example.importExmaple import Calculator    # import 예시

# Calculator 클래스 인스턴스 생성
calculator = Calculator()

# 사용자로부터 계산 종류 입력 받기
print("Select an operation:")
print("1. Addition")
print("2. Subtraction")
print("3. Multiplication")
print("4. Division")

choice = input("Enter choice (1/2/3/4): ")

# 사용자로부터 숫자 입력 받기
x = float(input("Enter the first number: "))
y = float(input("Enter the second number: "))

# 선택된 계산 수행
if choice == '1':
    result = calculator.add(x, y)
    operation = "Addition"
elif choice == '2':
    result = calculator.subtract(x, y)
    operation = "Subtraction"
elif choice == '3':
    result = calculator.multiply(x, y)
    operation = "Multiplication"
elif choice == '4':
    result = calculator.divide(x, y)
    operation = "Division"
else:
    print("Invalid choice")
    result = None
    operation = None

# 결과 출력
if result is not None and operation is not None:
    print(f"{operation}: {result}")

