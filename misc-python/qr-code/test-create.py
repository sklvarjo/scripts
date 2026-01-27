# source ~/python-yleinen-env/bin activate
# pip3 install qrcode
# pip3 install pillow
# python3 test-create.py
# deactivate

import qrcode

data = input("Enter text or URL: ")

gr = qrcode.make(data)
gr.save("qrcode.png")

print("Done!")
