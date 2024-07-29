#!/bin/bash

past=1
echo $past
test=$past

past+=2
test=$past

echo $test

past+=3
echo $past
test=$past

a = 200
b = 30
if b > a;
	echo "b is greater than a"
elif a == b :
	echo "a and b are equal"
else:
	echo "a is greater than b" 
