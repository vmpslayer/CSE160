interface Chat{
    command error_t hello(uint8_t username, nx_uint8_t clientPort);
    command error_t message(uint8_t msg);
    command error_t whisper(uint8_t username, uint8_t msg);
    command error_t list();
}