matrix_size = 4
A = [matrix_size * ["0" * 32] for i in range(matrix_size)]
B = [matrix_size * ["0" * 32] for i in range(matrix_size)]

test_number = 20

inputs_file = open("inputs.txt", "r")

for k in range(test_number):
    inputs_file.readline()
    for i in range(matrix_size):
        A[i] = [hex(int(x, 2))[2:] for x in inputs_file.readline().split()]
    inputs_file.readline()
    for i in range(matrix_size):
        B[i] = [hex(int(x, 2))[2:] for x in inputs_file.readline().split()]
    inputs_file.readline()
    matrix_a_file = open("a_matrix_" + str(k + 1) + ".txt", "w")
    matrix_b_file = open("b_matrix_" + str(k + 1) + ".txt", "w")
    for i in range(matrix_size):
        for j in range(matrix_size):
            matrix_a_file.write(A[j][i] + "\n")
            matrix_b_file.write(B[i][j] + "\n")
    matrix_a_file.close()
    matrix_b_file.close()

if __name__ == '__main__':
    pass
