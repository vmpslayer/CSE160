module ChatP{
    provides interface Chat;

    uses interface Transport;
}
implementation{
    nx_uint8_t serverAddr;
    nx_uint8_t serverPort;
    nx_uint8_t destAddr;
    nx_uint8_t destPort;

    command error_t Chat.hello(uint8_t username, nx_uint8_t clientPort){
        dbg(CHAT_CHANNEL, "HELLO: Initializing Handshake\n");

        serverPort = 80;
        serverAddr = 1;

        if(call Transport.initTransportClient(serverAddr, clientPort, serverPort) == SUCCESS){
            dbg(CHAT_CHANNEL, "HELLO: Handshake initialized successfully\n");
            return SUCCESS;
        }
        else{
            dbg(CHAT_CHANNEL, "HELLO: Failed to initialize handshake\n");
            return FAIL;
        }
    }

    command error_t Chat.message(uint8_t msg){
        dbg(CHAT_CHANNEL, "MESSAGE: Broadcasting message\n");

        destPort = 80;
        destAddr = 1;
        serverPort = 101;

        if(call Transport.writeMsg(TOS_NODE_ID, serverPort, destAddr, destPort) == SUCCESS){
            dbg(CHAT_CHANNEL, "MESSAGE: Broadcast SUCCESSFUL\n");
        }
        else{
            dbg(CHAT_CHANNEL, "MESSAGE: Broadcast FAILED\n");
        }
    }

    command error_t Chat.whisper(uint8_t username, uint8_t msg){
        dbg(CHAT_CHANNEL, "WHSIPER: Sending private message to %s\n", username);
    }

    command error_t Chat.list(){
        dbg(CHAT_CHANNEL, "LIST: Listing all users connected\n");
    }
}   