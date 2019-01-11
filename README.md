# Internet-Speed-Test
This script does a speed test against speedtest.net servers and returns a download speed

# Script Process Flow
This task finds the latitude and longitude of a machine to find the closest speedtest.net servers. 

It then sorts the servers removing duplicate companies and then by distance. 

It then hits the closest servers and downloads a 25Mb file 12 times for each server (just like speedtest.net) and calculates the average download speed. It does this for 8 servers (I chose 8 to have a bigger data set when comparing speeds).

It will then find the fastest speed of the 8 servers and saves it to a file on the computer.

This has been turned into a BigFix task as well. https://bigfix.me/fixlet/details/26595
