import numpy as np
import time
N = 2000
start_time = time.time()
A = np.random.rand(N,N)
end_generate = time.time()
np.save('array_file.npy', A)
end_save = time.time()
B = np.load('array_file.npy')
end_load = time.time()

elapsed_time = end_generate - start_time
print("Elapsed time generate:", elapsed_time, "seconds")

elapsed_time = end_save - end_generate
print("Elapsed time save:", elapsed_time, "seconds")

elapsed_time = end_load - end_save
print("Elapsed time load:", elapsed_time, "seconds")

# GEMM
mm_time = time.time()
np.matmul(A, A)
mm_time = time.time() - mm_time
