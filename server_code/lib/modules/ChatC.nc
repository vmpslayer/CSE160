configuration ChatC{
    provides interface Chat;
}
implementation{
    components ChatP;
    Chat = ChatP.Chat;

    components TransportP as Transport;
    ChatP.Transport -> Transport;
}