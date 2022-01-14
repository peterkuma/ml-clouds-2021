cimport cython
cimport numpy as np

import numpy as np
from cython.parallel import prange

@cython.boundscheck(False)
#@cython.wraparound(False)
def remap(
	np.ndarray[double, ndim=3] data,
	np.ndarray[double, ndim=1] lat,
	np.ndarray[double, ndim=1] lon,
	np.ndarray[double, ndim=2] lat2,
	np.ndarray[double, ndim=2] lon2,
):
	cdef long k = data.shape[0]
	cdef long n = len(lat)
	cdef long m = len(lon)
	cdef long n2 = lon2.shape[0]
	cdef long m2 = lon2.shape[1]
	cdef np.ndarray[double, ndim=3] data2 = np.full((k, n2, m2), np.nan, np.float64)
	cdef ki, i2, j2
	cdef np.ndarray[long, ndim=1] ii, jj
	cdef np.ndarray[long, ndim=2] ii2, jj2
	ii = np.searchsorted(lat, lat2.flatten())
	jj = np.searchsorted(lon, lon2.flatten())
	ii2 = ii.reshape((n2, m2))
	jj2 = jj.reshape((n2, m2))
	ii2[ii2 == n] = n - 1
	jj2[jj2 == m] = m - 1
	for i2 in range(n2):
		for j2 in range(m2):
			data2[:,i2,j2] = data[:,ii2[i2,j2],jj2[i2,j2]]
	return data2

@cython.boundscheck(False)
#@cython.wraparound(False)
def remap5(
	np.ndarray[double, ndim=3] data,
	np.ndarray[double, ndim=2] x,
	np.ndarray[double, ndim=2] y,
	double x21,
	double x22,
	double dx,
	double y21,
	double y22,
	double dy,
):
	cdef long long k, n, m
	k = data.shape[0]
	n = data.shape[1]
	m = data.shape[2]
	cdef long long n2 = np.floor((x22 - x21)/dx)
	cdef long long m2 = np.floor((y22 - y21)/dy)
	cdef np.ndarray[double, ndim=3] data2
	cdef np.ndarray[long long, ndim=2] ii, jj
	cdef long long i, j, i2, j2
	cdef double x2, y2
	data2 = np.full((k, n2, m2), np.nan, np.float64)
	num2 = np.zeros((k, n2, m2), np.int64)
	#for i in range(n):
	#	for j in range(m):
	#		pass
	#		i2 = int((x[i,j] - x21)/dx + 0.5)
	#		j2 = int((y[i,j] - y21)/dy + 0.5)
	#		if i2 < 0 or j2 < 0 or i2 >= n2 or j2 >= m2:
	#			continue
	#		data2[:,i2,j2] += data[:,i,j]
	#		num2[:,i2,j2] += 1
	#data2 /= num2
	for i2 in range(n2):
		for j2 in range(m2):
			#if num2[0,i2,j2] == 0:
				x2 = x21 + i2*dx
				y2 = y21 + j2*dy
				index = np.argmin((x - x2)**2 + (y - y2)**2)
				i, j = np.unravel_index(index, (n, m))
				data2[:,i2,j2] = data[:,i,j]
	return data2
