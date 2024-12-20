#ANDES Lab - University of California, Merced
#Author: UCM ANDES Lab
#$Author: abeltran2 $
#$LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
#! /usr/bin/python
import sys
from TOSSIM import *
from CommandMsg import *

class TestSim:
    moteids=[]
    # COMMAND TYPES
    CMD_PING = 0
    CMD_NEIGHBOR_DUMP = 1
    CMD_LINK_STATE_DUMP = 2
    CMD_ROUTE_DUMP = 3
    CMD_TEST_CLIENT = 4
    CMD_TEST_SERVER = 5
    CMD_FLOOD = 11
    CMD_DIJKSTRA = 12    
    CMD_LISTEN = 13
    CMD_CLOSE_PORT = 14
    CMD_WRITE = 15
    CMD_HELLO = 16
    CMD_MSG = 17
    CMD_WHISPER = 18
    CMD_LIST = 19


    # CHANNELS - see includes/channels.h
    COMMAND_CHANNEL="command"
    GENERAL_CHANNEL="general"

    # Project 1
    NEIGHBOR_CHANNEL="neighbor"
    FLOODING_CHANNEL="flooding"

    # Project 2
    ROUTING_CHANNEL="routing"

    # Project 3
    TRANSPORT_CHANNEL="transport"
    
    # Project 4 (God save us all)
    CHAT_CHANNEL="chat"

    # Personal Debuggin Channels for some of the additional models implemented.
    HASHMAP_CHANNEL="hashmap"

    # Initialize Vars
    numMote=0

    def __init__(self):
        #Simulating radio for sensor network
        self.t = Tossim([])
        self.r = self.t.radio()

        #Create a Command Packet
        self.msg = CommandMsg()
        self.pkt = self.t.newPacket()
        self.pkt.setType(self.msg.get_amType())

    # Load a topo file and use it.
    def loadTopo(self, topoFile):
        print 'Creating Topo!'
        # Read topology file.
        topoFile = 'topo/'+topoFile
        f = open(topoFile, "r")
        self.numMote = int(f.readline())
        print 'Number of Motes', self.numMote
        for line in f:
            s = line.split()
            if s:
                print " ", s[0], " ", s[1], " ", s[2]
                self.r.add(int(s[0]), int(s[1]), float(s[2]))
                if not int(s[0]) in self.moteids:
                    self.moteids=self.moteids+[int(s[0])]
                if not int(s[1]) in self.moteids:
                    self.moteids=self.moteids+[int(s[1])]

    # Load a noise file and apply it.
    def loadNoise(self, noiseFile):
        if self.numMote == 0:
            print "Create a topo first"
            return

        # Get and Create a Noise Model
        noiseFile = 'noise/'+noiseFile
        noise = open(noiseFile, "r")
        for line in noise:
            str1 = line.strip()
            if str1:
                val = int(str1)
            for i in self.moteids:
                self.t.getNode(i).addNoiseTraceReading(val)

        for i in self.moteids:
            print "Creating noise model for ",i
            self.t.getNode(i).createNoiseModel()

    def bootNode(self, nodeID):
        if self.numMote == 0:
            print "Create a topo first"
            return
        self.t.getNode(nodeID).bootAtTime(1333*nodeID)

    def bootAll(self):
        i=0;
        for i in self.moteids:
            self.bootNode(i)

    def moteOff(self, nodeID):
        self.t.getNode(nodeID).turnOff()
        
    def moteOn(self, nodeID):
        self.t.getNode(nodeID).turnOn()

    def run(self, ticks):
        for i in range(ticks):
            self.t.runNextEvent()

    # Rough run time. tickPerSecond does not work.
    def runTime(self, amount):
        self.run(amount*1000)

    # Generic Command
    def sendCMD(self, ID, dest, payloadStr):
        self.msg.set_dest(dest)
        self.msg.set_id(ID)
        self.msg.setString_payload(payloadStr)

        self.pkt.setData(self.msg.data)
        self.pkt.setDestination(dest)
        self.pkt.deliver(dest, self.t.time()+5)
        # print(ID)
    

    def ping(self, source, dest, msg):
        self.sendCMD(self.CMD_PING, source, "{0}{1}".format(chr(dest),msg))
    
    def neighborDMP(self, destination):
        self.sendCMD(self.CMD_NEIGHBOR_DUMP, destination, "neighbor command")

    def routeDMP(self, destination):
        self.sendCMD(self.CMD_ROUTE_DUMP, destination, "routing command")

    def addChannel(self, channelName, out=sys.stdout):
        print 'Adding Channel', channelName
        self.t.addChannel(channelName, out)

    def flood(self, source, dest, msg):
        self.sendCMD(self.CMD_FLOOD, source, "{0}{1}".format(chr(dest),msg))
        
    def linkStateDMP(self, dest):
        self.sendCMD(self.CMD_LINK_STATE_DUMP, dest, "link state command")
        
    def dijkstra(self, dest):
        self.sendCMD(self.CMD_DIJKSTRA, dest, "dijkstra command")
        
    def testClient(self, src, srcPort, dest, destPort):
        self.sendCMD(self.CMD_TEST_CLIENT, src, "{0}{1}{2}".format(chr(srcPort),chr(dest),chr(destPort)))
    
    def testServer(self, src, srcPort):
        self.sendCMD(self.CMD_TEST_SERVER, src, "{0}".format(chr(srcPort)))
        
    def listen(self, src, srcPort):
        self.sendCMD(self.CMD_LISTEN, src, "{0}".format(chr(srcPort)))
        
    def closePort(self, src, srcPort, dest, destPort):
        self.sendCMD(self.CMD_CLOSE_PORT, src, "{0}{1}{2}".format(chr(srcPort),chr(dest),chr(destPort)))
        
    def write(self, src, srcPort, dest, destPort):
        self.sendCMD(self.CMD_WRITE, src, "{0}{1}{2}".format(chr(srcPort),chr(dest),chr(destPort)))
        
    def hello(self, src, username, clientPort):
        self.sendCMD(self.CMD_HELLO, src, "{0}{1}".format(chr(username),chr(clientPort)))
    
    def msg(self, src, msg):
        self.sendCMD(self.CMD_MSG, src, "{0}".format(msg))
        
    def whisper(self, src, username, msg):
        self.sendCMD(self.CMD_WHISPER, src, "{0}{1}".format(chr(username), msg))
        
    def listuser(self, src):
        self.sendCMD(self.CMD_LIST, src)


def main():
    s = TestSim()
    s.runTime(10)
    s.loadTopo("example.topo")
    s.loadNoise("no_noise.txt")
    s.bootAll()
    # s.addChannel(s.COMMAND_CHANNEL)
    # s.addChannel(s.GENERAL_CHANNEL)
    # s.addChannel(s.NEIGHBOR_CHANNEL)
    # s.addChannel(s.FLOODING_CHANNEL)
    s.addChannel(s.ROUTING_CHANNEL)
    s.addChannel(s.TRANSPORT_CHANNEL)
    s.addChannel(s.CHAT_CHANNEL)

    s.runTime(20)
    
    
    for i in range(20):
        s.linkStateDMP(i)
        s.runTime(100)
    
    for i in range(20):    
        s.dijkstra(i)
        s.runTime(100)  
        
    # s.runTime(100)  
        
    s.testServer(1, 80)
    s.runTime(25)
    s.testClient(2, 101, 1, 80)
    s.runTime(50)    
    # s.write(2, 101, 1, 80)
    # s.runTime(50)   
    # s.closePort(2, 101, 1, 80)
    # s.runTime(50)

    # s.testClient(5, 102, 1, 80)
    # s.runTime(25)
    # s.testClient(8, 103, 1, 80)
    # s.runTime(25)
    # s.closePort(2, 101, 1, 80)
    
    s.runTime(1000)
    

    
    # for i in range(10):
    #     s.linkStateDMP(i)
    #     s.runTime(0)

    # s.runTime(10)

    # s.dijkstra(1)
    # s.runTime(100)
    

        
    # s.runTime(30)
    # s.ping(1, 2, "Howdy Neighbor!")
    # s.runTime(10)
    # s.ping(1, 5, "Hi!!!!!!!!!")
    # s.runTime(10)
    # s.flood(1, 3, "Flood packet")
    # s.ping(9, 2, "Holy Guacamole it works")
    # s.runTime(50)
        
    # s.runTime(1000)

    # s.runTime(200)
    # s.flood(2, 18, "MY BALLS")
    # s.runTime(300)
    
    # s.runTime(30)
    # s.neighborDMP(1)
    # s.runTime(20)
    # s.neighborDMP(2)

if __name__ == '__main__':
    main()