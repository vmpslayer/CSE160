// Config file
configuration FloodingC
{
    provides interface Flooding;
}
implementation // Specifies wiring
{
    components FloodingP;
    Flooding = FloodingP.Flooding;


}