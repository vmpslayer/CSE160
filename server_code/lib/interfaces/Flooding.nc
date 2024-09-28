interface Flooding{
    command error_t flood(void* data, uint8_t len);
    event void floodReceive(message_t msg, void* payload, uint8_t len);
}