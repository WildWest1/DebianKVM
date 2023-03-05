import sys
import xml.etree.ElementTree as ET

XML_FILE=sys.argv[1]
VM_DIR=sys.argv[2]

print("XML File: " + XML_FILE)
print("VM Folder: " + VM_DIR)


if VM_DIR == None or XML_FILE == None:
	print("Requires: [xml file] [vm volder] as parameters.")
	sys.exit(1)

# Parse the file
tree = ET.parse(XML_FILE)
root = tree.getroot()
sources = root.findall('./devices/disk/source')
sources[0].set("file", VM_DIR)
tree.write(XML_FILE)
print("Saved!")

