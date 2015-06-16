#!/usr/bin/env ruby
# Brian W. Gray
# 06.15.2015

## Script performs the following tasks
## 1.) sample 'random' address from the quote of the day server pool array.
## 2.) connect to qotd server and pull a quote every #{quoteRefresh} minutes.
## 3.) push quote to betabright

# qotd socket connection pulled from https://gist.github.com/six519/677b764c792fcc2c31c2

require 'rubygems'
require 'serialport'
require 'socket'

# Quote refresh time in seconds.
quoteRefresh = 1800


# QOTD Pool - Add multiple Quote of the day servers and the script will randomly select one as it cycles through
qotdPool = Array.new

qotdPool[0] = "alpha.mike-r.com"
qotdPool[1] = "alpha.mike-r.com"
qotdPool[2] = "alpha.mike-r.com"


#QOTD Server

#qotdServer = "alpha.mike-r.com"
qotdServer = qotdPool.sample


#params for serial port
port_str = "/dev/cu.usbserial"  #may be different for you
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE

sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

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


def pullQOTD(qotdServer)
begin
    
    $message = ""
    con = TCPSocket.open(qotdServer, 17)
    while buffer = con.gets
        $message = $message + buffer.strip + " "
    end
    rescue SocketError => e
    con = nil
    puts "The error is: " << e.message
    
    rescue Interrupt
    puts "\nTerminating script..."
end
end

begin
    
    qotdServer = qotdPool.sample # set a qotd server from the server pool for this query
    
    pullQOTD(qotdServer)
    

    $protosend = ("#{$INIT}" + "#{$WRITE}" + "A" + "\x1b\x20" + "#{$ROTATE}" + "#{$message}" + "#{$EOT}")
    sp.write("#{$protosend}")
    puts "#{qotdServer}: #{$message}"
    sleep(quoteRefresh.to_i)
    
end while 1<2

exit
