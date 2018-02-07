within TRANSFORM.Media.Fluids.FLiBe.Utilities_99_99Li7;
function d_T

  import TRANSFORM.Units.Conversions.Functions.Temperature_K.to_degF;
  import TRANSFORM.Units.Conversions.Functions.Density_kg_m3.from_lb_feet3;

  input SI.Temperature T;
  output SI.Density d;
algorithm
  d:= from_lb_feet3(138.68-0.01456*to_degF(T));
end d_T;
