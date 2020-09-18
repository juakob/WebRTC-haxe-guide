# WebRTC-haxe-guide
simple guide on implementing WebRTC with haxe

To start a WebRTC connection you will need some sort of communication channel, it could be a server or pass the data somehow.

If you want to connect two machines using WebRTC you will need two rols: someone that initiates the communication(make an offer) and someone that answers that offer.

We need the following actions by O(offer) and A(answer) to start ower communication channel:

                                          1-O generates an offer
                                          
                                          2-O upload the offer
                                          
                                          3-A gets the offer
                                          
                                          4-A use the offer 
                                          
                                          5-Generate the answer
                                          
                                          6-A uploads the answer
                                          
                                          7-B gets the answer
                                          
                                          8-the channel is creatd
                                          
                    
The step 3 and 7 are not shown in the code, but its just getting the data from the server and calling setSdp() with the stored SDP(connection info) and the right type(answer/offer)

Warning, depending on the browser you will need to be quick(~10s) doing the 5 to 7 steps or you will get an error in A, or at least I couldnt find a way to extend the timeout.
