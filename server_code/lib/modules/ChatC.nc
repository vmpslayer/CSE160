configuration ChatC{
    provides interface Chat;
}
implementation{
    components ChatP;
    Chat = ChatP.Chat;

    // Used for TCP handshake
    components TransportC as Transport;
    ChatP.Transport -> Transport;
}