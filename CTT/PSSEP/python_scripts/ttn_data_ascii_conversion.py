__author__ = 'fredrikanthonisen'

from sys import stdin, stderr
import struct

def litte_to_big_endian(hex_number):
    temp = ""
    for x in range(0, len(hex_number)):
        if(x%2 != 0):
            temp = hex_number[x-1: x+1] + temp
    return temp

def battery_conversion(hex_letter):
    if hex_letter == 'A':
        return 10
    elif hex_letter == 'B':
        return 11
    elif hex_letter == 'C':
        return 12
    elif hex_letter == 'D':
        return 13
    elif hex_letter == 'E':
        return 14
    elif hex_letter == 'F':
        return 15
    else:
        return int(hex_letter)

for line in stdin:
    temp = line[36:]
    measurements = []
    measurements.append(temp[2:10])
    measurements.append(temp[12:20])
    measurements.append(temp[22:30])
    measurements.append(temp[32:40])
    measurements.append(temp[42:50])
    if(len(temp) > 55):
        measurements.append(temp[52:60])
        measurements.append(temp[62:70])
        measurements.append(temp[72:80])
        measurements.append(temp[82:84])
    else:
        measurements.append(temp[52:54])
    
    if len(measurements) == 9:
        for x in range(0, 8):
            measurements[x] = litte_to_big_endian(measurements[x])
            measurements[x] = struct.unpack('!f', measurements[x].decode('hex'))[0]
        measurements[8] = (16*battery_conversion(measurements[8][0])) + battery_conversion(measurements[8][1])
    else:
        for x in range(0, 5):
            measurements[x] = litte_to_big_endian(measurements[x])
            measurements[x] = struct.unpack('!f', measurements[x].decode('hex'))[0]
        measurements[5] = (16*battery_conversion(measurements[5][0])) + battery_conversion(measurements[5][1])
    
    with open('output_10.txt', 'a') as data:
        data.writelines('%s ' % item for item in measurements)
        data.write('\n')
        data.close()
