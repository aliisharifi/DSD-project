# from time import time
from selenium.webdriver import Chrome, ActionChains
from selenium.webdriver.common.keys import Keys
import random

# from tqdm import tqdm

browser = Chrome()
browser.get('http://weitz.de/ieee/')
browser.maximize_window()

# going to ieee 754 single precision mode ##############################################################################

binary32key = browser.find_element_by_id('sizeButton32')
ActionChains(browser).click(binary32key).perform()

# finding needed elements ##############################################################################################

sign1 = browser.find_element_by_id('sign1')
mantissa1 = browser.find_element_by_id('mantissa1')
exp1 = browser.find_element_by_id('exp1')

sign2 = browser.find_element_by_id('sign2')
mantissa2 = browser.find_element_by_id('mantissa2')
exp2 = browser.find_element_by_id('exp2')

buttons = {
    'plus': browser.find_element_by_id('plusButton'),
    'minus': browser.find_element_by_id('minusButton'),
    'times': browser.find_element_by_id('timesButton'),
    'div': browser.find_element_by_id('divButton')
}

sign3 = browser.find_element_by_id('sign3')
mantissa3 = browser.find_element_by_id('mantissa3')
exp3 = browser.find_element_by_id('exp3')


# sending request ######################################################################################################


def clear_default_write_new(element, string):
    browser.execute_script("arguments[0].value = ''", element)
    element.send_keys(string)
    element.send_keys(Keys.RETURN)


def send_request(number1, number2=None, operation='times'):
    clear_default_write_new(sign1, number1[0])
    clear_default_write_new(mantissa1, number1[9:])
    clear_default_write_new(exp1, number1[1:9])
    if number2 is not None:
        clear_default_write_new(sign2, number2[0])
        clear_default_write_new(mantissa2, number2[9:])
        clear_default_write_new(exp2, number2[1:9])

    ActionChains(browser).click(buttons[operation]).perform()


# receiving answer #####################################################################################################


def receive_answer():
    sign = sign3.get_attribute('value')
    mantissa = mantissa3.get_attribute('value')
    exp = exp3.get_attribute('value')
    return sign + exp + mantissa


# deriving #############################################################################################################

matrix_size = 4
A = [matrix_size * ["0" * 32] for i in range(matrix_size)]
B = [matrix_size * ["0" * 32] for i in range(matrix_size)]
PE = [[matrix_size * ["0" * 32] for i in range(matrix_size)] for j in range(matrix_size)]
result = [matrix_size * ["0" * 32] for i in range(matrix_size)]


def matrix_multiplication(A, B, PE, result):
    for i in range(matrix_size):
        for j in range(matrix_size):
            send_request(A[0][i], B[i][j])
            for k in range(matrix_size):
                send_request(A[k][i])
                PE[j][k][i] = receive_answer()
                print(PE[j][k][i])

    for j in range(matrix_size):
        for i in range(matrix_size):
            for k in range(matrix_size):
                send_request(result[i][j], PE[j][i][k], 'plus')
                result[i][j] = receive_answer()


# generate random binary string ########################################################################################


def random_binary_32b():
    result = str(random.randint(0, 1))
    result += format(random.randint(1, 10) + 128, '08b')
    for i in range(23):
        result += str(random.randint(0, 1))
    return result


# write to file ########################################################################################################


inputs_file = open("inputs.txt", "w")
outputs_file = open("outputs_whit_python.txt", "w")

test_number = 20


def generate_matrix(matrix):
    for i in range(matrix_size):
        for j in range(matrix_size):
            temp = random_binary_32b()
            matrix[i][j] = temp
            inputs_file.write(temp + " ")
        inputs_file.write("\n")


def write_output(matrix):
    for i in range(matrix_size):
        for j in range(matrix_size):
            outputs_file.write(matrix[i][j] + " ")
        outputs_file.write("\n")


for k in range(test_number):
    inputs_file.write("A" + str(k + 1) + ":\n")
    generate_matrix(A)
    inputs_file.write("B" + str(k + 1) + ":\n")
    generate_matrix(B)
    inputs_file.write("\n")
    matrix_multiplication(A, B, PE, result)
    outputs_file.write("result" + str(k + 1) + ":\n")
    write_output(result)
    outputs_file.write("\n")

# closing ##############################################################################################################

browser.close()
quit()

if __name__ == '__main__':
    pass
