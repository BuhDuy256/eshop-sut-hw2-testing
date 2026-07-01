#!/bin/bash
killall node
cd "C:\Users\Duy\Desktop\eshop-sut-hw2-testing\backend" && node server.js &
cd "C:\Users\Duy\Desktop\eshop-sut-hw2-testing\frontend-web" && npm run dev &
cd "C:\Users\Duy\Desktop\eshop-sut-hw2-testing\frontend-admin" && npm run dev &
