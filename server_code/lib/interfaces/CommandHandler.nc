interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors();
   event void printRouteTable();
   event void printLinkState(uint16_t destination, uint8_t *payload);
   event void printDistanceVector();
   event void setTestServer(nx_uint8_t srcPort);
   event void setTestClient(nx_uint8_t srcPort, nx_uint8_t dest, nx_uint8_t destPort);
   event void setAppServer();
   event void setAppClient();
   event void flood(uint16_t destination, uint8_t *payload);
   event void Dijkstra();
   event void listen(nx_uint8_t src, nx_uint8_t srcPort);
   event void closePort(nx_uint8_t srcPort, nx_uint8_t dest, nx_uint8_t destPort);
   event void write(nx_uint8_t srcPort, nx_uint16_t dest, nx_uint16_t destPort);
   event void hello(uint8_t username, nx_uint8_t clientPort);
   event void message(uint8_t msg);
   event void whisper(uint8_t username, uint8_t msg);
   event void list();
}
