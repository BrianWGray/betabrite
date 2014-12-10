# BrianWGray
# Created 04.10.2014

require 'rubygems'
require 'serialport'
require 'time'

#params for serial port
port_str = "/dev/cu.usbserial"  #may be different for you
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

# puts ("\0\0\0\0\0\001" + "Z" + "00" + "\002" + "AA" + "\x1B" + " b" + "Secret Squirrel" + "\004")

#The 'Standard Transmission Frame' is:
#[ NULs ][ SOH ][ Type Code ][ Sign Address ][ STX ] [ Command Code ][ Data Field ] [ EOT ]
#We'll set some variables and build some other useful ones.
#Every message frame you send to the sign must start with the items listed below.


$NUL            = "\0\0\0\0\0\0";       # NUL - Sending 6 nulls for wake up sign and set baud neg.
$SOH            = "\x01";               # SOH - Start of header
$TYPE           = "Z";         		# Type Code - Z = All signs. See Protocol doc for more info
$SIGN_ADDR      = "00";      		# Sign Address - 00 = broadcast, 01 = sign address 1, etc
$STX            = "\x02";               # STX - Start of Text character

# These are other useful variables
$ETX            = "\x03"; 		# End of TeXt
$ESC            = "\x1b"; 		# Escape character
$EOT            = "\004"; 		# End of transmission

# We group some of the variables above to make life easy.
# This leaves us 2 type of init strings we can add to the front of our frame.
$INIT="#{$NUL}#{$SOH}#{$TYPE}#{$SIGN_ADDR}#{$STX}";		# Most used.
$INIT_NOSTX="#{$NUL}#{$SOH}#{$TYPE}#{$SIGN_ADDR}";		# Used for nested messages.

#If you look at the $INIT varaible you'll see I've grouped several varaibles together to make one.
#We now have $INIT and $EOT which will be the start and end of every frame we send to the sign. Now each frame becomes easier to construct.

#We now have a more compact string for the beginning of the frame and it's now:

#$INIT[ Command Code ][ Data Field ]$EOT

#One ASCII character that tells the sign what we want to do.

$WRITE		="A" # Write TEXT file
$READ		="B" # Read TEXT file *
$WRITE_SPEC	="E" # Write SPECIAL FUNCTION file
$READ_SPEC	="F" # Read SPECIAL FUNCTION file *
$WRITE_STRING	="G" # Write STRING file *
$READ_STRING	="H" # Read STRING file *
$WRITE_DOT	="I" # Write DOT file
$READ_DOT	="J" # Read DOT file *

#One ascii character that indicates the LABEL being accessed (page)
$LABEL	 = "A" #File A


#On one line signs, the Display Position is irrelevant, but still must be included so just send a blank or \x20
# Middle line = " " or \x20
# Top Line = \x22
# Bottom Line = \x26
# Fill - all = \x30

#Note = \x20 seems to be best on the Betabrite sign.


# I create DPOS ... notice the -esc- to start the Mode Field:
#$DPOS="\x1b\x20";


#Mode Code - Single ASCII character that represents a mode for displaying the ASCII message.
#Examples:
#Here are 3 of the many modes.Examples:
$ROTATE ="\x61" # Message travels right to left.
$HOLD ="\x62" # Message remains stationary.
$FLASH ="\x63" # Message remains stationary and flashes.


begin
    time = Time.new
    $message= time.hour.to_s + ":" + time.min.to_s
    $protosend = ("#{$INIT}" + "#{$WRITE}" + "A" + "\x1b\x20" + "#{$HOLD}" + "#{$message}" + "#{$EOT}")
    sp.write("#{$protosend}")
    sleep(60)
end while 1 < 2


#sp.write("\0\0\0\0\0\001" + "Z" + "00" + "\002" + "AA" + "\x1B" + " b" + "Working String" + "\004")


exit