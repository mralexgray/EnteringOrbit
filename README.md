EnteringOrbit(eo)
=============
Command line tool for Mac.  

Tail the remote log file via ssh,  
then broadcast the stream as WebSocket client / Standard Output.

##usage

login to somewhere server as someone with ssh and tail some.log, then output to text.

	EnteringOrbit -s someone@somewhere -t ./some.txt > output.txt


if wanna use key for ssh,

	EnteringOrbit -s "someone@somewhere -i identity_file" -t ./some.log > output.txt

if wanna publish result as WebSocket client,

	EnteringOrbit -s "someone@somewhere -i identity_file" -t ./some.log -p ws://

##The scenerio
When the some.log will be adding lines by the other program,  
the eo can catch that changes as standard output.


**somewhere : server-peer**/  
./some.log  
**->**	
tail & publish to **client-peer**  
**->**  
WebSocket / standard output / NSDistributedNotification