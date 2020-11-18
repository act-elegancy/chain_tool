package Operational_Toolkit_v2
  model ClosedVolume
    extends Modelica.Fluid.Vessels.ClosedVolume;
  equation

  end ClosedVolume;

  model MassFlowSource_T
    extends Modelica.Fluid.Sources.MassFlowSource_T;
  equation

  end MassFlowSource_T;

  model Pipe_IdealHeatTransfer
    // Redeclare heat transfer model (ideal heat exchange)
    extends Modelica.Fluid.Pipes.DynamicPipe(redeclare model HeatTransfer = Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.IdealFlowHeatTransfer);
  end Pipe_IdealHeatTransfer;

  model Pipe_ConstantFlowHeatTransfer
    extends Modelica.Fluid.Pipes.DynamicPipe(redeclare model HeatTransfer = Modelica.Fluid.Pipes.BaseClasses.HeatTransfer.ConstantFlowHeatTransfer(alpha0 = 0.34));
  equation

  end Pipe_ConstantFlowHeatTransfer;

  model Compressor_isentropic
    replaceable package Medium = Modelica.Media.Interfaces.PartialPureSubstance;
    Modelica.Fluid.Interfaces.FluidPort_a port_a(redeclare package Medium = Medium) annotation(
      Placement(visible = true, transformation(origin = {-100, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {-100, -2}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Fluid.Interfaces.FluidPort_b port_b(redeclare package Medium = Medium) annotation(
      Placement(visible = true, transformation(origin = {100, -4}, extent = {{-10, -10}, {10, 10}}, rotation = 0), iconTransformation(origin = {100, -4}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    Modelica.Blocks.Interfaces.RealInput P_ratio annotation(
      Placement(visible = true, transformation(origin = {-100, 120}, extent = {{-20, -20}, {20, 20}}, rotation = -90), iconTransformation(origin = {-100, 120}, extent = {{-20, -20}, {20, 20}}, rotation = -90)));
    Medium.ThermodynamicState state1, state2;
    parameter Real eta = 1 "compressor efficiency";
    Modelica.SIunits.Power W;
  equation
// Mass balance
    port_a.m_flow + port_b.m_flow = 0;
// Get thermodynamic states from ports. Note that for the stream flowing out of the compressor, inStream is needed for flow in the design direction
    state1 = Medium.setState_ph(port_a.p, port_a.h_outflow);
    state2 = Medium.setState_ph(port_b.p, port_b.h_outflow);
// Assume isentropic compression
    Medium.specificEntropy(state1) = Medium.specificEntropy(state2);
// Fix compression ratio
    if port_a.m_flow > 0 then
      port_b.p / port_a.p = P_ratio;
    else
      port_b.p / port_a.p = 1;
// don't decompress
    end if;
// Equation for flow in reverse direction (no work in the reverse direction)
    port_a.h_outflow = inStream(port_b.h_outflow);
// Equation for compressor work
//  W = port_a.m_flow * (inStream(port_b.h_outflow) - port_a.h_outflow) / eta;
    W = port_a.m_flow * (port_b.h_outflow - port_a.h_outflow) / eta;
// W = 10000;
    annotation(
      Icon(graphics = {Line(origin = {0, 0.0357617}, points = {{-100, 99.9642}, {-100, -100.036}, {100, -20.0358}, {100, 19.9642}, {-100, 99.9642}, {-100, -100.036}}), Text(extent = {{-150, 12}, {150, -18}}, textString = "compressor")}));
  end Compressor_isentropic;

  model FixedTemperature
    extends Modelica.Thermal.HeatTransfer.Sources.FixedTemperature;
  equation

  end FixedTemperature;

  package H2
    // 6th order taylor model from consumet
    extends Modelica.Media.Interfaces.PartialPureSubstance(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.pTX, singleState = false, Temperature(min = 273.15, max = 303.15, start = 300), AbsolutePressure(min = 1e6, max = 40e6, start = 6e6));
    constant MolarMass MM_const = 2.016e-3 "Molar mass";
    // kg/mol

    redeclare record ThermodynamicState "A selection of variables that uniquely defines the thermodynamic state"
      extends Modelica.Icons.Record;
      AbsolutePressure p "Absolute pressure of medium";
      Temperature T "Temperature of medium";
    end ThermodynamicState;
  
    redeclare model extends BaseProperties(T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default)) "Base properties of medium"
        Real Pr, Tr;
  
      equation
        Pr = (p * 1e-6 - 1) / (40 - 1);
        Tr = (T - 273.15) / (303.15 - 273.15);
//d = p/R/T;
        d = MM * (437.623 + Pr ^ 1.0 * 16961.04 + Pr ^ 2.0 * (-4056.23) + Pr ^ 3.0 * 207.1778 + Pr ^ 4.0 * 433.718 + Pr ^ 5.0 * (-170.5648) + Pr ^ 6.0 * 12.28372 + Tr ^ 1.0 * (-48.09765) + Tr ^ 1.0 * Pr ^ 1.0 * (-1854.212) + Tr ^ 1.0 * Pr ^ 2.0 * 714.9401 + Tr ^ 1.0 * Pr ^ 3.0 * 107.2221 + Tr ^ 1.0 * Pr ^ 4.0 * (-219.7232) + Tr ^ 1.0 * Pr ^ 5.0 * 66.36184 + Tr ^ 2.0 * 6.403281 + Tr ^ 2.0 * Pr ^ 1.0 * 200.4548 + Tr ^ 2.0 * Pr ^ 2.0 * (-101.5664) + Tr ^ 2.0 * Pr ^ 3.0 * (-2.253024) + Tr ^ 2.0 * Pr ^ 4.0 * 11.53657 + Tr ^ 3.0 * (-1.839775) + Tr ^ 3.0 * Pr ^ 1.0 * (-11.80001) + Tr ^ 3.0 * Pr ^ 2.0 * 3.362076 + Tr ^ 4.0 * Pr ^ 1.0 * (-2.709656) + Tr ^ 4.0 * Pr ^ 2.0 * 2.924457);
        h = (7213.956 + Pr ^ 1.0 * 281.7351 + Pr ^ 2.0 * 176.4006 + Pr ^ 4.0 * (-38.61002) + Pr ^ 6.0 * 8.269283 + Tr ^ 1.0 * 861.3027 + Tr ^ 1.0 * Pr ^ 1.0 * 72.27537 + Tr ^ 1.0 * Pr ^ 2.0 * (-38.51922) + Tr ^ 1.0 * Pr ^ 4.0 * 5.739548 + Tr ^ 2.0 * 3.226658 + Tr ^ 2.0 * Pr ^ 1.0 * (-2.796348) + Tr ^ 3.0 * Pr ^ 1.0 * (-1.343903) + Tr ^ 3.0 * Pr ^ 3.0 * 1.150659) / MM;
        u = h - p / d;
        p = state.p;
        T = state.T;
        MM = MM_const;
        R = 8.3144 / MM;
    end BaseProperties;
  
    redeclare function extends setState_pTX "Set the thermodynamic state record from p and T (X not needed)"
      algorithm
        state := ThermodynamicState(p = p, T = T);
    end setState_pTX;
  
    redeclare function extends setState_phX "Set the thermodynamic state record from p and h (X not needed)"
      protected
        Real pr, hr;
  
      algorithm
        pr := (p * 1e-6 - 1) / (40 - 1);
        hr := (h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060);
        state := ThermodynamicState(p = p, T = 273.1497 + pr ^ 1.0 * (-9.818327) + pr ^ 2.0 * (-4.822566) + pr ^ 3.0 * (-2.528819) + pr ^ 4.0 * 5.963713 + pr ^ 5.0 * (-4.083106) + pr ^ 6.0 * 1.037863 + hr ^ 1.0 * 46.32792 + hr ^ 1.0 * pr ^ 1.0 * (-4.115097) + hr ^ 1.0 * pr ^ 2.0 * 3.076093 + hr ^ 1.0 * pr ^ 3.0 * (-0.8564101) + hr ^ 1.0 * pr ^ 4.0 * (-0.4089363) + hr ^ 1.0 * pr ^ 5.0 * 0.2853492 + hr ^ 2.0 * (-0.3475331) + hr ^ 2.0 * pr ^ 1.0 * 0.8080364 + hr ^ 2.0 * pr ^ 2.0 * (-0.9458613) + hr ^ 2.0 * pr ^ 3.0 * 0.5194099 + hr ^ 2.0 * pr ^ 4.0 * (-0.1275396) + hr ^ 3.0 * 0.03261113 + hr ^ 3.0 * pr ^ 1.0 * (-0.09893147) + hr ^ 3.0 * pr ^ 2.0 * 0.1350867 + hr ^ 3.0 * pr ^ 3.0 * (-0.04398887) + hr ^ 4.0 * 0.0514136 + hr ^ 5.0 * (-0.03577434));
    end setState_phX;
  
    redeclare function extends pressure "Return the pressure from the thermodynamic state"
      algorithm
        p := state.p;
    end pressure;
  
    redeclare function extends temperature "Return the temperature from the thermodynamic state"
      algorithm
        T := state.T;
    end temperature;
  
    redeclare function extends density "Return the density from the thermodynamic state"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 1) / (40 - 1);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        d := 2.016e-3 * (437.623 + Pr ^ 1.0 * 16961.04 + Pr ^ 2.0 * (-4056.23) + Pr ^ 3.0 * 207.1778 + Pr ^ 4.0 * 433.718 + Pr ^ 5.0 * (-170.5648) + Pr ^ 6.0 * 12.28372 + Tr ^ 1.0 * (-48.09765) + Tr ^ 1.0 * Pr ^ 1.0 * (-1854.212) + Tr ^ 1.0 * Pr ^ 2.0 * 714.9401 + Tr ^ 1.0 * Pr ^ 3.0 * 107.2221 + Tr ^ 1.0 * Pr ^ 4.0 * (-219.7232) + Tr ^ 1.0 * Pr ^ 5.0 * 66.36184 + Tr ^ 2.0 * 6.403281 + Tr ^ 2.0 * Pr ^ 1.0 * 200.4548 + Tr ^ 2.0 * Pr ^ 2.0 * (-101.5664) + Tr ^ 2.0 * Pr ^ 3.0 * (-2.253024) + Tr ^ 2.0 * Pr ^ 4.0 * 11.53657 + Tr ^ 3.0 * (-1.839775) + Tr ^ 3.0 * Pr ^ 1.0 * (-11.80001) + Tr ^ 3.0 * Pr ^ 2.0 * 3.362076 + Tr ^ 4.0 * Pr ^ 1.0 * (-2.709656) + Tr ^ 4.0 * Pr ^ 2.0 * 2.924457);
    end density;
  
    redeclare function extends specificEnthalpy "Return the specific enthalpy from the thermodynamic state"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 1) / (40 - 1);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        h := (7213.956 + Pr ^ 1.0 * 281.7351 + Pr ^ 2.0 * 176.4006 + Pr ^ 4.0 * (-38.61002) + Pr ^ 6.0 * 8.269283 + Tr ^ 1.0 * 861.3027 + Tr ^ 1.0 * Pr ^ 1.0 * 72.27537 + Tr ^ 1.0 * Pr ^ 2.0 * (-38.51922) + Tr ^ 1.0 * Pr ^ 4.0 * 5.739548 + Tr ^ 2.0 * 3.226658 + Tr ^ 2.0 * Pr ^ 1.0 * (-2.796348) + Tr ^ 3.0 * Pr ^ 1.0 * (-1.343903) + Tr ^ 3.0 * Pr ^ 3.0 * 1.150659) / 2.016e-3;
    end specificEnthalpy;
  
    redeclare function extends specificEntropy "Return the specific entropy from the thermodynamic state"
      protected
        Real Tr, Pr;
  
      algorithm
   Pr := (state.p * 1e-6 - 1) / (40 - 1);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        s := ((85.03628)+Pr^1.0*(-178.954)+Pr^2.0*(744.3632)+Pr^3.0*(-1887.247)+Pr^4.0*(2655.94)+Pr^5.0*(-1915.575)+Pr^6.0*(551.3883)+Tr^1.0*(1.67609)+Tr^1.0*Pr^1.0*(14.01634)+Tr^1.0*Pr^2.0*(-34.49786)+Tr^1.0*Pr^3.0*(24.02755)+Tr^1.0*Pr^4.0*(13.66036)+Tr^1.0*Pr^5.0*(-16.61229)+Tr^2.0*(-0.4074466)+Tr^2.0*Pr^2.0*(6.598304)+Tr^2.0*Pr^3.0*(-25.83269)+Tr^2.0*Pr^4.0*(26.80698)+Tr^3.0*Pr^1.0*(-7.367386)+Tr^3.0*Pr^2.0*(26.17667)+Tr^3.0*Pr^3.0*(-34.73876)+Tr^4.0*(2.076966)+Tr^4.0*Pr^1.0*(-5.005642)+Tr^4.0*Pr^2.0*(16.925)+Tr^5.0*Pr^1.0*(-4.216638)) / 2.016e-3;
    end specificEntropy;
    
  
  
    redeclare function extends specificInternalEnergy "Return the specific internal energy from the thermodynamic state"
      algorithm
        u := specificEnthalpy(state) - state.p / density(state.p, state.T);
    end specificInternalEnergy;
  
    redeclare function extends dynamicViscosity "Return specific heat capacity at constant volume"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 0.01) / (70 - 0.01);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        eta := 1e-6 * (8.376351 + Pr ^ 1.0 * 0.4960503 + Pr ^ 2.0 * 4.32647 + Pr ^ 3.0 * (-4.093603) + Pr ^ 4.0 * 2.328414 + Pr ^ 5.0 * (-0.7374059) + Pr ^ 6.0 * 0.09694489 + Tr ^ 1.0 * 0.6374942 + Tr ^ 1.0 * Pr ^ 1.0 * (-0.1703525) + Tr ^ 1.0 * Pr ^ 2.0 * (-0.711275) + Tr ^ 1.0 * Pr ^ 3.0 * 0.9779357 + Tr ^ 1.0 * Pr ^ 4.0 * (-0.5781216) + Tr ^ 1.0 * Pr ^ 5.0 * 0.1318107 + Tr ^ 2.0 * (-0.01372378) + Tr ^ 2.0 * Pr ^ 1.0 * 0.03534364 + Tr ^ 2.0 * Pr ^ 2.0 * 0.06870629 + Tr ^ 2.0 * Pr ^ 3.0 * (-0.101565) + Tr ^ 2.0 * Pr ^ 4.0 * 0.04035988 + Tr ^ 3.0 * 0.007522214 + Tr ^ 3.0 * Pr ^ 1.0 * (-0.01337785) + Tr ^ 3.0 * Pr ^ 2.0 * 0.007104198 + Tr ^ 3.0 * Pr ^ 3.0 * 0.0008715189 + Tr ^ 4.0 * (-0.01006183) + Tr ^ 4.0 * Pr ^ 1.0 * 0.00413409 + Tr ^ 4.0 * Pr ^ 2.0 * (-0.003308206) + Tr ^ 5.0 * 0.007695032 + Tr ^ 6.0 * (-0.002408013));
    end dynamicViscosity;
  end H2;

  package CO2
    // Medium properties for CO2 using the 6th order taylor series from CONSUMET
    extends Modelica.Media.Interfaces.PartialPureSubstance(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.pTX, singleState = false, Temperature(min = 273.15, max = 303.15, start = 300), AbsolutePressure(min = 3.49e6, max = 25e6, start = 6e6));
    constant MolarMass MM_const = 44.01e-3 "Molar mass";
    // kg/mol

    redeclare record ThermodynamicState "A selection of variables that uniquely defines the thermodynamic state"
      extends Modelica.Icons.Record;
      AbsolutePressure p "Absolute pressure of medium";
      Temperature T "Temperature of medium";
    end ThermodynamicState;

    redeclare model extends BaseProperties(T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default)) "Base properties of medium"
        Real Pr, Tr;
        // Reduced temperature and pressure (0 - 1 between consumet fitting bounds)

      equation
        Pr = (p * 1e-6 - 3.49) / (25 - 3.49);
// Provide bounds
        Tr = (T - 273.15) / (303.15 - 273.15);
// Provide correct bounds
        d = MM * (21072.82 + Pr ^ 1.0 * 4653.387 + Pr ^ 2.0 * (-7085.171) + Pr ^ 3.0 * 20896.92 + Pr ^ 4.0 * (-45737.62) + Pr ^ 5.0 * 49987.2 + Pr ^ 6.0 * (-20367.57) + Tr ^ 1.0 * (-4685.38) + Tr ^ 1.0 * Pr ^ 1.0 * 8451.596 + Tr ^ 1.0 * Pr ^ 2.0 * (-33869.9) + Tr ^ 1.0 * Pr ^ 3.0 * 102322.8 + Tr ^ 1.0 * Pr ^ 4.0 * (-140859.0) + Tr ^ 1.0 * Pr ^ 5.0 * 67581.85 + Tr ^ 2.0 * (-2379.01) + Tr ^ 2.0 * Pr ^ 1.0 * 16686.46 + Tr ^ 2.0 * Pr ^ 2.0 * (-80542.25) + Tr ^ 2.0 * Pr ^ 3.0 * 143707.9 + Tr ^ 2.0 * Pr ^ 4.0 * (-81557.15) + Tr ^ 3.0 * (-1376.98) + Tr ^ 3.0 * Pr ^ 1.0 * 29946.82 + Tr ^ 3.0 * Pr ^ 2.0 * (-70324.58) + Tr ^ 3.0 * Pr ^ 3.0 * 47357.56 + Tr ^ 4.0 * (-6800.745) + Tr ^ 4.0 * Pr ^ 1.0 * 14068.37 + Tr ^ 4.0 * Pr ^ 2.0 * (-11947.64) + Tr ^ 5.0 * 1515.465 + Tr ^ 5.0 * Pr ^ 1.0 * 716.0218 + Tr ^ 6.0 * (-469.8712));
// Use molar mass to convert to kg/m3
        h = (8802.251 + Pr ^ 1.0 * (-1070.912) + Pr ^ 2.0 * 2537.239 + Pr ^ 3.0 * (-7384.257) + Pr ^ 4.0 * 16346.7 + Pr ^ 5.0 * (-18065.93) + Pr ^ 6.0 * 7421.21 + Tr ^ 1.0 * 3360.194 + Tr ^ 1.0 * Pr ^ 1.0 * (-3106.563) + Tr ^ 1.0 * Pr ^ 2.0 * 12223.78 + Tr ^ 1.0 * Pr ^ 3.0 * (-37254.67) + Tr ^ 1.0 * Pr ^ 4.0 * 51784.81 + Tr ^ 1.0 * Pr ^ 5.0 * (-25029.21) + Tr ^ 2.0 * 895.3787 + Tr ^ 2.0 * Pr ^ 1.0 * (-6160.785) + Tr ^ 2.0 * Pr ^ 2.0 * 29824.99 + Tr ^ 2.0 * Pr ^ 3.0 * (-53664.22) + Tr ^ 2.0 * Pr ^ 4.0 * 30705.88 + Tr ^ 3.0 * 502.9731 + Tr ^ 3.0 * Pr ^ 1.0 * (-11206.08) + Tr ^ 3.0 * Pr ^ 2.0 * 26635.81 + Tr ^ 3.0 * Pr ^ 3.0 * (-18202.6) + Tr ^ 4.0 * 2587.651 + Tr ^ 4.0 * Pr ^ 1.0 * (-5463.311) + Tr ^ 4.0 * Pr ^ 2.0 * 4824.878 + Tr ^ 5.0 * (-559.801) + Tr ^ 5.0 * Pr ^ 1.0 * (-388.1272) + Tr ^ 6.0 * 202.6378) / MM;
//Use molar mass to convert to J/kg
        u = h - p / d;
        p = state.p;
        T = state.T;
        MM = MM_const;
        R = 8.3144 / MM;
    end BaseProperties;

    redeclare function extends setState_pTX "Set the thermodynamic state record from p and T (X not needed)"
      algorithm
        state := ThermodynamicState(p = p, T = T);
    end setState_pTX;

    redeclare function extends setState_phX "Set the thermodynamic state record from p and h (X not needed)"
      protected

      algorithm
        state := ThermodynamicState(p = p, T = 270.537 + ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 1.0 * 71.8527 + ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 2.0 * (-528.4152) + ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 3.0 * 1390.616 + ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 4.0 * (-1555.265) + ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 5.0 * 707.2677 + ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 6.0 * (-83.7842) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 1.0 * 41.83432 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 1.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 1.0 * 742.1878 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 1.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 2.0 * (-1211.291) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 1.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 3.0 * (-245.0976) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 1.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 4.0 * 1492.461 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 1.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 5.0 * (-660.773) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 2.0 * (-118.7282) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 2.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 1.0 * (-970.954) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 2.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 2.0 * 3126.187 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 2.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 3.0 * (-2431.274) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 2.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 4.0 * 346.1382 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 3.0 * 265.7507 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 3.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 1.0 * 479.3526 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 3.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 2.0 * (-1527.502) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 3.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 3.0 * 960.4853 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 4.0 * (-763.0302) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 4.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 1.0 * (-12.15898) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 4.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 2.0 * 129.1612 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 5.0 * 963.6274 + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 5.0 * ((p * 1e-6 - 3.49) / (25 - 3.49)) ^ 1.0 * (-117.8068) + ((h - 8519.215) / (21133.544 - 8519.215)) ^ 6.0 * (-350.8199));
    end setState_phX;

    redeclare function extends pressure "Return the pressure from the thermodynamic state"
      algorithm
        p := state.p;
    end pressure;

    redeclare function extends temperature "Return the temperature from the thermodynamic state"
      algorithm
        T := state.T;
    end temperature;

    redeclare function extends density "Return the density from the thermodynamic state"
      protected
        Real Tr, Pr;

      algorithm
        Pr := (state.p * 1e-6 - 3.49) / (25 - 3.49);
// Provide bounds
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        d := 44.01e-3 * (21072.82 + Pr ^ 1.0 * 4653.387 + Pr ^ 2.0 * (-7085.171) + Pr ^ 3.0 * 20896.92 + Pr ^ 4.0 * (-45737.62) + Pr ^ 5.0 * 49987.2 + Pr ^ 6.0 * (-20367.57) + Tr ^ 1.0 * (-4685.38) + Tr ^ 1.0 * Pr ^ 1.0 * 8451.596 + Tr ^ 1.0 * Pr ^ 2.0 * (-33869.9) + Tr ^ 1.0 * Pr ^ 3.0 * 102322.8 + Tr ^ 1.0 * Pr ^ 4.0 * (-140859.0) + Tr ^ 1.0 * Pr ^ 5.0 * 67581.85 + Tr ^ 2.0 * (-2379.01) + Tr ^ 2.0 * Pr ^ 1.0 * 16686.46 + Tr ^ 2.0 * Pr ^ 2.0 * (-80542.25) + Tr ^ 2.0 * Pr ^ 3.0 * 143707.9 + Tr ^ 2.0 * Pr ^ 4.0 * (-81557.15) + Tr ^ 3.0 * (-1376.98) + Tr ^ 3.0 * Pr ^ 1.0 * 29946.82 + Tr ^ 3.0 * Pr ^ 2.0 * (-70324.58) + Tr ^ 3.0 * Pr ^ 3.0 * 47357.56 + Tr ^ 4.0 * (-6800.745) + Tr ^ 4.0 * Pr ^ 1.0 * 14068.37 + Tr ^ 4.0 * Pr ^ 2.0 * (-11947.64) + Tr ^ 5.0 * 1515.465 + Tr ^ 5.0 * Pr ^ 1.0 * 716.0218 + Tr ^ 6.0 * (-469.8712));
    end density;

    redeclare function extends specificEnthalpy "Return the specific enthalpy from the thermodynamic state"
      protected
        Real Tr, Pr;

      algorithm
        Pr := (state.p * 1e-6 - 3.49) / (25 - 3.49);
// Provide bounds
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        h := (8802.251 + Pr ^ 1.0 * (-1070.912) + Pr ^ 2.0 * 2537.239 + Pr ^ 3.0 * (-7384.257) + Pr ^ 4.0 * 16346.7 + Pr ^ 5.0 * (-18065.93) + Pr ^ 6.0 * 7421.21 + Tr ^ 1.0 * 3360.194 + Tr ^ 1.0 * Pr ^ 1.0 * (-3106.563) + Tr ^ 1.0 * Pr ^ 2.0 * 12223.78 + Tr ^ 1.0 * Pr ^ 3.0 * (-37254.67) + Tr ^ 1.0 * Pr ^ 4.0 * 51784.81 + Tr ^ 1.0 * Pr ^ 5.0 * (-25029.21) + Tr ^ 2.0 * 895.3787 + Tr ^ 2.0 * Pr ^ 1.0 * (-6160.785) + Tr ^ 2.0 * Pr ^ 2.0 * 29824.99 + Tr ^ 2.0 * Pr ^ 3.0 * (-53664.22) + Tr ^ 2.0 * Pr ^ 4.0 * 30705.88 + Tr ^ 3.0 * 502.9731 + Tr ^ 3.0 * Pr ^ 1.0 * (-11206.08) + Tr ^ 3.0 * Pr ^ 2.0 * 26635.81 + Tr ^ 3.0 * Pr ^ 3.0 * (-18202.6) + Tr ^ 4.0 * 2587.651 + Tr ^ 4.0 * Pr ^ 1.0 * (-5463.311) + Tr ^ 4.0 * Pr ^ 2.0 * 4824.878 + Tr ^ 5.0 * (-559.801) + Tr ^ 5.0 * Pr ^ 1.0 * (-388.1272) + Tr ^ 6.0 * 202.6378) / 44.01e-3;
    end specificEnthalpy;

    redeclare function extends specificEntropy "Return the specific entropy from the thermodynamic state"
      protected
        Real Tr, Pr;

      algorithm
        Pr := (state.p * 1e-6 - 3.49) / (25 - 3.49);
// Provide bounds
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        s := (44.00988 + Pr ^ 1.0 * (-7.650587) + Pr ^ 2.0 * 9.562115 + Pr ^ 3.0 * (-26.3342) + Pr ^ 4.0 * 56.91673 + Pr ^ 5.0 * (-62.16016) + Pr ^ 6.0 * 25.35546 + Tr ^ 1.0 * 12.30211 + Tr ^ 1.0 * Pr ^ 1.0 * (-11.32158) + Tr ^ 1.0 * Pr ^ 2.0 * 43.28916 + Tr ^ 1.0 * Pr ^ 3.0 * (-128.8232) + Tr ^ 1.0 * Pr ^ 4.0 * 176.7881 + Tr ^ 1.0 * Pr ^ 5.0 * (-84.78861) + Tr ^ 2.0 * 2.581455 + Tr ^ 2.0 * Pr ^ 1.0 * (-21.39906) + Tr ^ 2.0 * Pr ^ 2.0 * 101.8058 + Tr ^ 2.0 * Pr ^ 3.0 * (-181.0023) + Tr ^ 2.0 * Pr ^ 4.0 * 102.7215 + Tr ^ 3.0 * 1.751497 + Tr ^ 3.0 * Pr ^ 1.0 * (-37.60029) + Tr ^ 3.0 * Pr ^ 2.0 * 88.46188 + Tr ^ 3.0 * Pr ^ 3.0 * (-59.84766) + Tr ^ 4.0 * 8.572334 + Tr ^ 4.0 * Pr ^ 1.0 * (-17.7687) + Tr ^ 4.0 * Pr ^ 2.0 * 15.36097 + Tr ^ 5.0 * (-1.916723) + Tr ^ 5.0 * Pr ^ 1.0 * (-1.064243) + Tr ^ 6.0 * 0.6351254) / 44.01e-3;
    end specificEntropy;

    redeclare function extends specificInternalEnergy "Return the specific internal energy from the thermodynamic state"
      algorithm
        u := specificEnthalpy(state) - state.p / density(state.p, state.T);
    end specificInternalEnergy;

    redeclare function extends dynamicViscosity "Return specific heat capacity at constant volume"
      protected
        Real Tr, Pr;

      algorithm
        Pr := (state.p * 1e-6 - 3.49) / (25 - 3.49);
// Provide bounds
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        eta := 0.1004035 + Pr ^ 1.0 * 0.05788191 + Pr ^ 2.0 * (-0.05776843) + Pr ^ 3.0 * 0.1497942 + Pr ^ 4.0 * (-0.2967477) + Pr ^ 5.0 * 0.3050739 + Pr ^ 6.0 * (-0.1194723) + Tr ^ 1.0 * (-0.05983554) + Tr ^ 1.0 * Pr ^ 1.0 * 0.05355807 + Tr ^ 1.0 * Pr ^ 2.0 * (-0.2275723) + Tr ^ 1.0 * Pr ^ 3.0 * 0.624803 + Tr ^ 1.0 * Pr ^ 4.0 * (-0.8084524) + Tr ^ 1.0 * Pr ^ 5.0 * 0.3724628 + Tr ^ 2.0 * (-0.001980343) + Tr ^ 2.0 * Pr ^ 1.0 * 0.1036416 + Tr ^ 2.0 * Pr ^ 2.0 * (-0.4584673) + Tr ^ 2.0 * Pr ^ 3.0 * 0.7706467 + Tr ^ 2.0 * Pr ^ 4.0 * (-0.4181423) + Tr ^ 3.0 * (-0.01075427) + Tr ^ 3.0 * Pr ^ 1.0 * 0.1575088 + Tr ^ 3.0 * Pr ^ 2.0 * (-0.3482293) + Tr ^ 3.0 * Pr ^ 3.0 * 0.2194173 + Tr ^ 4.0 * (-0.03289404) + Tr ^ 4.0 * Pr ^ 1.0 * 0.06192891 + Tr ^ 4.0 * Pr ^ 2.0 * (-0.04336129) + Tr ^ 5.0 * 0.008261685 + Tr ^ 5.0 * Pr ^ 1.0 * (-0.00209548) + Tr ^ 6.0 * (-0.001186093);
    end dynamicViscosity;

    redeclare function extends specificHeatCapacityCp "C_P/ J/kg.K"
      protected
        Real Tr, Pr;

      algorithm
        Pr := (state.p * 1e-6 - 3.49) / (25 - 3.49);
// Provide bounds
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        cp := ((-12321.57 * Pr ^ 1.0 * Tr ^ 1.0) - 33618.24 * Pr ^ 1.0 * Tr ^ 2.0 - 21853.244 * Pr ^ 1.0 * Tr ^ 3.0 - 1940.636 * Pr ^ 1.0 * Tr ^ 4.0 - 3106.563 * Pr ^ 1.0 + 59649.98 * Pr ^ 2.0 * Tr ^ 1.0 + 79907.43 * Pr ^ 2.0 * Tr ^ 2.0 + 19299.512 * Pr ^ 2.0 * Tr ^ 3.0 + 12223.78 * Pr ^ 2.0 - 107328.44 * Pr ^ 3.0 * Tr ^ 1.0 - 54607.8 * Pr ^ 3.0 * Tr ^ 2.0 - 37254.67 * Pr ^ 3.0 + 61411.76 * Pr ^ 4.0 * Tr ^ 1.0 + 51784.81 * Pr ^ 4.0 - 25029.21 * Pr ^ 5.0 + 1790.7574 * Tr ^ 1.0 + 1508.9193 * Tr ^ 2.0 + 10350.604 * Tr ^ 3.0 - 2799.005 * Tr ^ 4.0 + 1215.8268 * Tr ^ 5.0 + 3360.194) / (303.15 - 273.15) / 44.01e-3;
    end specificHeatCapacityCp;
  end CO2;

  model System "System properties and default values (ambient, flow direction, initialization)"
    package Medium = Modelica.Media.Interfaces.PartialMedium "Medium model for default start values" annotation(
      choicesAllMatching = true);
    parameter Modelica.SIunits.AbsolutePressure p_ambient = 6e6 "Default ambient pressure" annotation(
      Dialog(group = "Environment"));
    parameter Modelica.SIunits.Temperature T_ambient = 300 "Default ambient temperature" annotation(
      Dialog(group = "Environment"));
    parameter Modelica.SIunits.Acceleration g = Modelica.Constants.g_n "Constant gravity acceleration" annotation(
      Dialog(group = "Environment"));
    // Assumptions
    parameter Boolean allowFlowReversal = true "= false to restrict to design flow direction (port_a -> port_b)" annotation(
      Dialog(tab = "Assumptions"),
      Evaluate = true);
    parameter Modelica.Fluid.Types.Dynamics energyDynamics = Modelica.Fluid.Types.Dynamics.DynamicFreeInitial "Default formulation of energy balances" annotation(
      Evaluate = true,
      Dialog(tab = "Assumptions", group = "Dynamics"));
    parameter Modelica.Fluid.Types.Dynamics massDynamics = energyDynamics "Default formulation of mass balances" annotation(
      Evaluate = true,
      Dialog(tab = "Assumptions", group = "Dynamics"));
    final parameter Modelica.Fluid.Types.Dynamics substanceDynamics = massDynamics "Default formulation of substance balances" annotation(
      Evaluate = true,
      Dialog(tab = "Assumptions", group = "Dynamics"));
    final parameter Modelica.Fluid.Types.Dynamics traceDynamics = massDynamics "Default formulation of trace substance balances" annotation(
      Evaluate = true,
      Dialog(tab = "Assumptions", group = "Dynamics"));
    parameter Modelica.Fluid.Types.Dynamics momentumDynamics = Modelica.Fluid.Types.Dynamics.SteadyState "Default formulation of momentum balances, if options available" annotation(
      Evaluate = true,
      Dialog(tab = "Assumptions", group = "Dynamics"));
    // Initialization
    parameter Modelica.SIunits.MassFlowRate m_flow_start = 0 "Default start value for mass flow rates" annotation(
      Dialog(tab = "Initialization"));
    parameter Modelica.SIunits.AbsolutePressure p_start = p_ambient "Default start value for pressures" annotation(
      Dialog(tab = "Initialization"));
    parameter Modelica.SIunits.Temperature T_start = T_ambient "Default start value for temperatures" annotation(
      Dialog(tab = "Initialization"));
    // Advanced
    parameter Boolean use_eps_Re = false "= true to determine turbulent region automatically using Reynolds number" annotation(
      Evaluate = true,
      Dialog(tab = "Advanced"));
    parameter Modelica.SIunits.MassFlowRate m_flow_nominal = if use_eps_Re then 1 else 1e2 * m_flow_small "Default nominal mass flow rate" annotation(
      Dialog(tab = "Advanced", enable = use_eps_Re));
    parameter Real eps_m_flow(min = 0) = 1e-4 "Regularization of zero flow for |m_flow| < eps_m_flow*m_flow_nominal" annotation(
      Dialog(tab = "Advanced", enable = use_eps_Re));
    parameter Modelica.SIunits.AbsolutePressure dp_small(min = 0) = 1 "Default small pressure drop for regularization of laminar and zero flow" annotation(
      Dialog(tab = "Advanced", group = "Classic", enable = not use_eps_Re));
    parameter Modelica.SIunits.MassFlowRate m_flow_small(min = 0) = 1e-2 "Default small mass flow rate for regularization of laminar and zero flow" annotation(
      Dialog(tab = "Advanced", group = "Classic", enable = not use_eps_Re));
  initial equation
//assert(use_eps_Re, "*** Using classic system.m_flow_small and system.dp_small."
//       + " They do not distinguish between laminar flow and regularization of zero flow."
//       + " Absolute small values are error prone for models with local nominal values."
//       + " Moreover dp_small can generally be obtained automatically."
//       + " Please update the model to new system.use_eps_Re = true  (see system, Advanced tab). ***",
//       level=AssertionLevel.warning);
    annotation(
      defaultComponentName = "system",
      defaultComponentPrefixes = "inner",
      missingInnerMessage = "
  Your model is using an outer \"system\" component but
  an inner \"system\" component is not defined.
  For simulation drag Modelica.Fluid.System into your model
  to specify system properties.",
      Icon(coordinateSystem(preserveAspectRatio = false, extent = {{-100, -100}, {100, 100}}), graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}, lineColor = {0, 0, 255}, fillColor = {255, 255, 255}, fillPattern = FillPattern.Solid), Text(extent = {{-150, 150}, {150, 110}}, lineColor = {0, 0, 255}, textString = "%name"), Line(points = {{-86, -30}, {82, -30}}), Line(points = {{-82, -68}, {-52, -30}}), Line(points = {{-48, -68}, {-18, -30}}), Line(points = {{-14, -68}, {16, -30}}), Line(points = {{22, -68}, {52, -30}}), Line(points = {{74, 84}, {74, 14}}), Polygon(points = {{60, 14}, {88, 14}, {74, -18}, {60, 14}}, fillPattern = FillPattern.Solid), Text(extent = {{16, 20}, {60, -18}}, textString = "g"), Text(extent = {{-90, 82}, {74, 50}}, textString = "defaults"), Line(points = {{-82, 14}, {-42, -20}, {2, 30}}, thickness = 0.5), Ellipse(extent = {{-10, 40}, {12, 18}}, pattern = LinePattern.None, fillColor = {255, 0, 0}, fillPattern = FillPattern.Solid)}),
      Documentation(info = "<html>
  <p>
   A system component is needed in each fluid model to provide system-wide settings, such as ambient conditions and overall modeling assumptions.
   The system settings are propagated to the fluid models using the inner/outer mechanism.
  </p>
  <p>
   A model should never directly use system parameters.
   Instead a local parameter should be declared, which uses the global setting as default.
   The only exceptions are:</p>
   <ul>
    <li>the gravity system.g,</li>
    <li>the global system.eps_m_flow, which is used to define a local m_flow_small for the local m_flow_nominal:
        <pre>m_flow_small = system.eps_m_flow*m_flow_nominal</pre>
    </li>
   </ul>
  <p>
   The global system.m_flow_small and system.dp_small are classic parameters.
   They do not distinguish between laminar flow and regularization of zero flow.
   Absolute small values are error prone for models with local nominal values.
   Moreover dp_small can generally be obtained automatically.
   Consider using the new system.use_eps_Re = true (see Advanced tab).
  </p>
  </html>"));
  end System;

  model Boundary_pT
    extends Modelica.Fluid.Sources.Boundary_pT;
  equation

  end Boundary_pT;

  package Examples
    extends Modelica.Icons.ExamplesPackage;

    model H2_pipe_example
      extends Modelica.Icons.Example;
      Operational_Toolkit_v2.Boundary_pT boundary_pT(redeclare package Medium = H2, T = 300, nPorts = 1, p = 2e6) annotation(
        Placement(visible = true, transformation(origin = {-110, 12}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Pipe_IdealHeatTransfer pipe(redeclare package Medium = H2, diameter = 0.0254 * 12, length = 10 * 1000, nNodes = 10, roughness = 4.5e-05) annotation(
        Placement(visible = true, transformation(origin = {-6, 14}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      inner System system(p_ambient = 2e+06) annotation(
        Placement(visible = true, transformation(origin = {-86, 84}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Operational_Toolkit_v2.MassFlowSource_T massFlowSource_T(redeclare package Medium = H2, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {52, 14}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      FixedTemperature fixedTemperature(T = 300) annotation(
        Placement(visible = true, transformation(origin = {-20, 46}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Operational_Toolkit_v2.Ramp ramp(duration = 100, height = -200) annotation(
        Placement(visible = true, transformation(origin = {94, 14}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
    equation
      for i in 1:pipe.nNodes loop
        connect(fixedTemperature.port, pipe.heatPorts[i]);
      end for;
      connect(boundary_pT.ports[1], pipe.port_a) annotation(
        Line(points = {{-100, 12}, {-16, 12}, {-16, 14}, {-16, 14}}, color = {0, 127, 255}));
      connect(ramp.y, massFlowSource_T.m_flow_in) annotation(
        Line(points = {{84, 14}, {64, 14}, {64, 22}, {62, 22}}, color = {0, 0, 127}));
      connect(massFlowSource_T.ports[1], pipe.port_b) annotation(
        Line(points = {{42, 14}, {2, 14}, {2, 14}, {4, 14}}, color = {0, 127, 255}));
    end H2_pipe_example;

    model DomesticDemand
      extends Modelica.Icons.Example;
      Modelica.Blocks.Tables.CombiTable1Ds DomesticDemand_normalized(fileName = "C:/Users/edwar/OneDrive/Desktop/ELEGANCY_FINAL/CASE_STUDY_PAPER/domestic_demand_normalized.txt", smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "tab1", tableOnFile = true) annotation(
        Placement(visible = true, transformation(origin = {-22, 24}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression t_s(y = time) annotation(
        Placement(visible = true, transformation(origin = {-68, 24}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(t_s.y, DomesticDemand_normalized.u) annotation(
        Line(points = {{-56, 24}, {-36, 24}, {-36, 24}, {-34, 24}}, color = {0, 0, 127}));
    end DomesticDemand;

    model Production_SMR
    replaceable package Medium = H2;
      extends Modelica.Icons.Example;  
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid(amplitude = 7.141 / 2, falling = 4 *3600, offset = 0, rising = 4 *3600) annotation(
        Placement(visible = true, transformation(origin = {47.75, 22.08}, extent = {{-11, -11}, {11, 11}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController1(bandwidth = 2.5) annotation(
        Placement(visible = true, transformation(origin = {-20.25, 22.08}, extent = {{-11, -11}, {11, 11}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint(k = 15) annotation(
        Placement(visible = true, transformation(origin = {-67.25, 3.08002}, extent = {{-7, -7}, {7, 7}}, rotation = 0)));
  Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid1(amplitude = 7.141 / 2, falling = 4 * 3600, offset = 0, rising = 4 * 3600) annotation(
        Placement(visible = true, transformation(origin = {47.75, -13.92}, extent = {{-11, -11}, {11, 11}}, rotation = 0)));
  Modelica.Blocks.Logical.OnOffController onOffController2(bandwidth = 3) annotation(
        Placement(visible = true, transformation(origin = {-16.25, -13.92}, extent = {{-11, -11}, {11, 11}}, rotation = 0)));
  Modelica.Blocks.Math.Add H2_production annotation(
        Placement(visible = true, transformation(origin = {84, 4}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  MassFlowSource_T massFlowSource_T(redeclare package Medium = Medium, T = 300, nPorts = 1, use_m_flow_in = true)  annotation(
        Placement(visible = true, transformation(origin = {-66, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Operational_Toolkit_v2.ClosedVolume Storage(redeclare package Medium = Medium, V = 5e5, nPorts = 2, p_start = 15e6, use_portsData = false)  annotation(
        Placement(visible = true, transformation(origin = {-8, -50}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Operational_Toolkit_v2.MassFlowSource_T massFlowSource_T1(redeclare package Medium = Medium, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {36,-56}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
  Operational_Toolkit_v2.FixedTemperature fixedTemperature(T = 300)  annotation(
        Placement(visible = true, transformation(origin = {-29, -41}, extent = {{-5, -5}, {5, 5}}, rotation = 0)));
  Modelica.Blocks.Sources.RealExpression storagePressure(y = Storage.medium.p / 1e6)  annotation(
        Placement(visible = true, transformation(origin = {-68, -20}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.RealExpression t_s(y = time) annotation(
        Placement(visible = true, transformation(origin = {83, -64}, extent = {{7, -6}, {-7, 6}}, rotation = 0)));
  Modelica.Blocks.Tables.CombiTable1Ds DomesticDemand_normalized(fileName = "C:/Users/edwar/OneDrive/Desktop/ELEGANCY_FINAL/CASE_STUDY_PAPER/domestic_demand_normalized.txt", smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "tab1", tableOnFile = true) annotation(
        Placement(visible = true, transformation(origin = {83, -49}, extent = {{5, -5}, {-5, 5}}, rotation = 0)));
  Modelica.Blocks.Math.Gain gain(k = -14)  annotation(
        Placement(visible = true, transformation(origin = {63, -49}, extent = {{5, -5}, {-5, 5}}, rotation = 0)));
  Modelica.Blocks.Sources.RealExpression H2_demand_kgpers(y = -1 * gain.y) annotation(
        Placement(visible = true, transformation(origin = {72, -83}, extent = {{18, -7}, {-18, 7}}, rotation = 0)));
  inner Operational_Toolkit_v2.System system annotation(
        Placement(visible = true, transformation(origin = {-86, 60}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      connect(triggeredTrapezoid.y, H2_production.u1) annotation(
        Line(points = {{60, 22}, {72, 22}, {72, 10}}, color = {0, 0, 127}));
      connect(triggeredTrapezoid1.y, H2_production.u2) annotation(
        Line(points = {{60, -14}, {70, -14}, {70, -10}, {72, -10}, {72, -2}}, color = {0, 0, 127}));
      connect(PressureSetPoint.y, onOffController1.reference) annotation(
        Line(points = {{-60, 4}, {-50, 4}, {-50, 29}, {-33, 29}}, color = {0, 0, 127}));
      connect(PressureSetPoint.y, onOffController2.reference) annotation(
        Line(points = {{-60, 4}, {-50, 4}, {-50, -8}, {-30, -8}, {-30, -8}}, color = {0, 0, 127}));
      connect(massFlowSource_T.ports[1], Storage.ports[1]) annotation(
        Line(points = {{-56, -50}, {-28, -50}, {-28, -68}, {-10, -68}, {-10, -60}, {-8, -60}}, color = {0, 127, 255}));
      connect(massFlowSource_T1.ports[1], Storage.ports[2]) annotation(
        Line(points = {{26, -56}, {-8, -56}, {-8, -60}}, color = {0, 127, 255}));
      connect(fixedTemperature.port, Storage.heatPort) annotation(
        Line(points = {{-24, -40}, {-18, -40}, {-18, -50}, {-18, -50}}, color = {191, 0, 0}));
      connect(H2_production.y, massFlowSource_T.m_flow_in) annotation(
        Line(points = {{95, 4}, {98, 4}, {98, -32}, {-86, -32}, {-86, -42}, {-76, -42}}, color = {0, 0, 127}));
      connect(storagePressure.y, onOffController2.u) annotation(
        Line(points = {{-56, -20}, {-30, -20}, {-30, -20}, {-30, -20}}, color = {0, 0, 127}));
      connect(storagePressure.y, onOffController1.u) annotation(
        Line(points = {{-56, -20}, {-42, -20}, {-42, 15}, {-33, 15}}, color = {0, 0, 127}));
      connect(t_s.y, DomesticDemand_normalized.u) annotation(
        Line(points = {{75, -64}, {75, -52.5}, {89, -52.5}, {89, -49}}, color = {0, 0, 127}));
      connect(DomesticDemand_normalized.y[1], gain.u) annotation(
        Line(points = {{78, -48}, {68, -48}, {68, -48}, {70, -48}}, color = {0, 0, 127}));
      connect(gain.y, massFlowSource_T1.m_flow_in) annotation(
        Line(points = {{58, -48}, {46, -48}, {46, -48}, {46, -48}}, color = {0, 0, 127}));
      connect(onOffController2.y, triggeredTrapezoid1.u) annotation(
        Line(points = {{-4, -14}, {34, -14}, {34, -14}, {34, -14}}, color = {255, 0, 255}));
  connect(onOffController1.y, triggeredTrapezoid.u) annotation(
        Line(points = {{-8, 22}, {34, 22}, {34, 22}, {34, 22}}, color = {255, 0, 255}));
      annotation(
        Documentation(info = "<html><head></head><body>Example to show how to model an H2 production facility with multiple operating points.&nbsp;</body></html>"));
    end Production_SMR;

    model Humber_Region_CaseStudy
      extends Modelica.Icons.Example;
    
      replaceable package Medium_H2 = H2;
      replaceable package Medium_CO2 = CO2;
      // GLOBAL VARIABLES
      inner Modelica.Fluid.System system(T_ambient = 300.00, p_ambient = 6.00e+06) annotation(
        Placement(visible = true, transformation(origin = {906, 911}, extent = {{-34, -33}, {34, 33}}, rotation = 0)));
      Modelica.Thermal.HeatTransfer.Sources.FixedTemperature fixedTemperature(T = system.T_ambient) annotation(
        Placement(visible = true, transformation(origin = {905, 797}, extent = {{-31, -31}, {31, 31}}, rotation = 0)));
      // VOLUMES AT EACH CELL (including storage)
      Modelica.Fluid.Vessels.ClosedVolume s37(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 5, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-72, -617}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s38(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 4, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {108, -489}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s39(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 3, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {225, -459}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s19(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 3, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {21, 413}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s22(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 3, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-449, -68}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s23(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 3, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-279, -14}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s24(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 4, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-109, 39}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s25(redeclare package Medium = Medium_H2, V = 1e3, nPorts = 5, p_start = 6.00e+06, use_HeatTransfer = true, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {40, 79}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s28(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 5, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-422, -418}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s29(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 4, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-253, -364}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s30(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 4, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-84, -312}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s31(redeclare package Medium = Medium_H2, use_HeatTransfer = true, p_start = 6.00e+06, V = 1.00e+00, nPorts = 4, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {84, -266}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      // DYNAMIC PIPE MODELS FOR EACH CONNECTION
      Modelica.Fluid.Pipes.DynamicPipe pipe_24_19(redeclare package Medium = Medium_H2, diameter = 9.144e-01, length = 2.935e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-44, 226}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_24_30(redeclare package Medium = Medium_H2, diameter = 9.144e-01, length = 2.259e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-96, -137}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_25_30(redeclare package Medium = Medium_H2, diameter = 9.144e-01, length = 2.982e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-22, -116}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_25_31(redeclare package Medium = Medium_H2, diameter = 9.144e-01, length = 2.273e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {62, -93}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_28_22(redeclare package Medium = Medium_H2, diameter = 0.7, length = 2.259e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-436, -243}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_28_23(redeclare package Medium = Medium_H2, diameter = 0.7, length = 3.195e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-351, -216}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_28_29(redeclare package Medium = Medium_H2, diameter = 0.7, length = 2.259e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-338, -391}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_29_37(redeclare package Medium = Medium_H2, diameter = 0.7, length = 2.884e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-163, -490}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_31_37(redeclare package Medium = Medium_H2, diameter = 0.7, length = 3.047e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {6, -441}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_38_37(redeclare package Medium = Medium_H2, diameter = 0.7, length = 2.518e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {18, -553}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_38_39(redeclare package Medium = Medium_H2, diameter = 0.7, length = 1.561e+04, nNodes = 2, nParallel = 1, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {166, -474}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_production_37(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-50, -661}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_production_38(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {129, -533}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_production_24(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-87, -6}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_production_25(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {62, 34}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_production_28(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-400, -462}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_production_29(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-231, -408}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_production_31(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {105, -310}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid37(amplitude = 7.141, falling = 3600, offset = 0, rising = 3600) annotation(
        Placement(visible = true, transformation(origin = {-20.25, -661.92}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController37(bandwidth = 8e6) annotation(
        Placement(visible = true, transformation(origin = {-12.25, -661.92}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint37(k = 150e5) annotation(
        Placement(visible = true, transformation(origin = {-5.25, -656.92}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_signal37(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {-5.25, -666.92}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid38(amplitude = 12.853 / 2, falling = 3600, offset = 0, rising = 3600) annotation(
        Placement(visible = true, transformation(origin = {159.62, -533.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController38(bandwidth = 4e6) annotation(
        Placement(visible = true, transformation(origin = {167.62, -533.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint38(k = 150e5) annotation(
        Placement(visible = true, transformation(origin = {174.62, -528.79}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_signal38(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {196.62, -542.79}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid24(amplitude = 7.141, falling = 3600, offset = 0, rising = 3600) annotation(
        Placement(visible = true, transformation(origin = {-57.10, -6.41}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController24(bandwidth = 8e6) annotation(
        Placement(visible = true, transformation(origin = {-49.10, -6.41}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint24(k = 150e5) annotation(
        Placement(visible = true, transformation(origin = {-42.10, -1.41}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_signal24(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {-38.1, -11.41}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid25(amplitude = 2.856, falling = 3600, offset = 0, rising = 3600) annotation(
        Placement(visible = true, transformation(origin = {92.25, 34.05}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController25(bandwidth = 8e6) annotation(
        Placement(visible = true, transformation(origin = {100.25, 34.05}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint25(k = 150e5) annotation(
        Placement(visible = true, transformation(origin = {107.25, 39.05}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_signal25(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {107.25, 29.05}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid28(amplitude = 14.282 / 2, falling = 3600 * 6, offset = 0, rising = 3600 * 6) annotation(
        Placement(visible = true, transformation(origin = {-370.16, -462.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController28(bandwidth = 4e6) annotation(
        Placement(visible = true, transformation(origin = {-362.16, -462.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint28(k = 150e5) annotation(
        Placement(visible = true, transformation(origin = {-347.16, -451.79}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_signal28(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {-315.16, -473.79}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid29(amplitude = 2.856, falling = 3600, offset = 0, rising = 3600) annotation(
        Placement(visible = true, transformation(origin = {-201.10, -408.89}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController29(bandwidth = 8e6) annotation(
        Placement(visible = true, transformation(origin = {-193.10, -408.89}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint29(k = 150e5) annotation(
        Placement(visible = true, transformation(origin = {-186.10, -403.89}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_signal29(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {-186.10, -413.89}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid31(amplitude = 2.856, falling = 3600, offset = 0, rising = 3600) annotation(
        Placement(visible = true, transformation(origin = {135.70, -310.75}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController31(bandwidth = 8e6) annotation(
        Placement(visible = true, transformation(origin = {143.70, -310.75}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant PressureSetPoint31(k = 150e5) annotation(
        Placement(visible = true, transformation(origin = {150.70, -305.75}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_signal31(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {150.70, -315.75}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      // DEMAND AT EACH CELL
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_37(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-50.25, -686.92}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_38(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {129.62, -558.79}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_39(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {246.81, -528.98}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_19(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {42.59, 343.10}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_22(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-427.01, -138.16}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_23(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-257.17, -83.96}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_24(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-87.10, -31.41}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_25(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {62.25, 9.05}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_28(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-400.16, -487.79}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_29(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-231.10, -433.89}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_30(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-61.81, -381.62}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T H2_demand_31(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {105.70, -335.75}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand37(y = (-2.48 * normalizedDomesticDemand.y[1]) - 4.81) annotation(
        Placement(visible = true, transformation(origin = {-32.25, -686.92}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand38(y = (-0.29 * normalizedDomesticDemand.y[1]) - 10.77) annotation(
        Placement(visible = true, transformation(origin = {147.62, -558.79}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand39(y = (-0.21 * normalizedDomesticDemand.y[1]) - 0.00) annotation(
        Placement(visible = true, transformation(origin = {264.81, -528.98}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand19(y = (-1.87 * normalizedDomesticDemand.y[1]) - 0.00) annotation(
        Placement(visible = true, transformation(origin = {60.59, 343.10}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand22(y = (-4.09 * normalizedDomesticDemand.y[1]) - 0.00) annotation(
        Placement(visible = true, transformation(origin = {-409.01, -138.16}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand23(y = (-3.07 * normalizedDomesticDemand.y[1]) - 0.00) annotation(
        Placement(visible = true, transformation(origin = {-201.17, -90.96}, extent = {{29, -10}, {-29, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand24(y = (-1.38 * normalizedDomesticDemand.y[1]) - 0.00) annotation(
        Placement(visible = true, transformation(origin = {-69.10, -31.41}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand25(y = (-0.74 * normalizedDomesticDemand.y[1]) - 0.00) annotation(
        Placement(visible = true, transformation(origin = {80.25, 9.05}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand28(y = (-5.52 * normalizedDomesticDemand.y[1]) - 0.25) annotation(
        Placement(visible = true, transformation(origin = {-382.16, -487.79}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand29(y = (-2.12 * normalizedDomesticDemand.y[1]) - 0.34) annotation(
        Placement(visible = true, transformation(origin = {-213.10, -433.89}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand30(y = (-5.80 * normalizedDomesticDemand.y[1]) - 0.23) annotation(
        Placement(visible = true, transformation(origin = {-43.81, -381.62}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression totalH2Demand31(y = (-5.60 * normalizedDomesticDemand.y[1]) - 1.74) annotation(
        Placement(visible = true, transformation(origin = {123.70, -335.75}, extent = {{23, -3}, {-23, 3}}, rotation = 0)));
      // DOMESTIC DEMAND
      Modelica.Blocks.Sources.RealExpression t_s(y = time) annotation(
        Placement(visible = true, transformation(origin = {946, 668}, extent = {{18, -16}, {-18, 16}}, rotation = 0)));
      Modelica.Blocks.Tables.CombiTable1Ds normalizedDomesticDemand(fileName = "C:/Users/edwar/OneDrive/Desktop/ELEGANCY_FINAL/CASE_STUDY_PAPER/domestic_demand_normalized.txt", smoothness = Modelica.Blocks.Types.Smoothness.ContinuousDerivative, tableName = "tab1", tableOnFile = true) annotation(
        Placement(visible = true, transformation(origin = {874, 678}, extent = {{30, -30}, {-30, 30}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume storage1(redeclare package Medium = Medium_H2, V = 1e6, nPorts = 1, p_start = 150e5, use_HeatTransfer = true, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {122, 175}, extent = {{-20, -20}, {20, 20}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T to_storage(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {132, 112}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T from_storage(redeclare package Medium = Medium_H2, T = 300, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {134, 46}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Blocks.Logical.OnOffController onOffController(bandwidth = 0.5e6) annotation(
        Placement(visible = true, transformation(origin = {208.25, 150.05}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression realExpression(y = s25.medium.p) annotation(
        Placement(visible = true, transformation(origin = {215.25, 145.05}, extent = {{2, -1}, {-2, 1}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid(amplitude = 35, falling = 100000, offset = -triggeredTrapezoid.amplitude / 2, rising = 100000) annotation(
        Placement(visible = true, transformation(origin = {200.25, 150.05}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
      Modelica.Blocks.Sources.Constant constant1(k = 6000000.00) annotation(
        Placement(visible = true, transformation(origin = {215.25, 155.05}, extent = {{1, -1}, {-1, 1}}, rotation = 0)));
      Modelica.Blocks.Math.Gain gainin(k = 1) annotation(
        Placement(visible = true, transformation(origin = {157, 111}, extent = {{5, -5}, {-5, 5}}, rotation = 0)));
      Modelica.Blocks.Math.Gain gain(k = -1) annotation(
        Placement(visible = true, transformation(origin = {167, 61}, extent = {{5, -5}, {-5, 5}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression realExpression1(y = s25.medium.p) annotation(
        Placement(visible = true, transformation(origin = {183, -102}, extent = {{-29, -10}, {29, 10}}, rotation = 0)));
      storage_control storage_control1 annotation(
        Placement(visible = true, transformation(origin = {201, 85}, extent = {{-7, -7}, {7, 7}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression storage_pressure1(y = storage1.medium.p) annotation(
        Placement(visible = true, transformation(origin = {190, 110}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.SIunits.MassFlowRate totalDemand;
      Modelica.Blocks.Continuous.LimPID pid(Ti = 100, controllerType = Modelica.Blocks.Types.SimpleController.P, k = -10, limitsAtInit = true, yMax = 40, yMin = -40) annotation(
        Placement(visible = true, transformation(origin = {240, -48}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression realExpression3(y = 6e6) annotation(
        Placement(visible = true, transformation(origin = {183, -50}, extent = {{-29, -10}, {29, 10}}, rotation = 0)));
      Modelica.Blocks.Continuous.FirstOrder firstOrder(T = 100) annotation(
        Placement(visible = true, transformation(origin = {188, 40}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_to_storage(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {222, 682}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Blocks.Continuous.LimPID PID_injection(Ti = 10, controllerType = Modelica.Blocks.Types.SimpleController.P, k = 1, limitsAtInit = true, yMax = 40) annotation(
        Placement(visible = true, transformation(origin = {274, 822}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression co2SetPoint(y = 12e6) annotation(
        Placement(visible = true, transformation(origin = {190, 822}, extent = {{-44, -18}, {44, 18}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression pressure_co2_end(y = s41_CO2.medium.p) annotation(
        Placement(visible = true, transformation(origin = {304, 736}, extent = {{-44, -18}, {44, 18}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s22_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 1, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-779, 821}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s23_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-779, 753}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s28_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-775, 560}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s29_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-657, 436}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s24_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 4, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-781, 688}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s30_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 2, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-551, 748}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s37_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-553, 816}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s25_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-787, 624}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s31_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-635, 520}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s38_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-657, 614}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s41_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 3, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {99, 732}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s39_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 2, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {-661, 752}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Vessels.ClosedVolume s43_CO2(redeclare package Medium = Medium_CO2, V = 1, nPorts = 2, p_start = 12e6, use_portsData = false) annotation(
        Placement(visible = true, transformation(origin = {235, 614}, extent = {{-19, -19}, {19, 19}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_22_23(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_23_24(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_23_28(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_28_29(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_29_24(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_30_37(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_37_38(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_31_41(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_30_31(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_24_25(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_38_39(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_25_41(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Pipes.DynamicPipe pipe_CO2_39_43(redeclare package Medium = Medium_CO2, diameter = 26 * 0.0254, length = 2.935e+04, nNodes = 2, nParallel = 1, p_a_start = 12e6, p_b_start = 12e6, roughness = 0.0475e-03, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {-446, 702}, extent = {{-14, -14}, {14, 14}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_to_storage2(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {302, 600}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      Modelica.Blocks.Continuous.LimPID PID(Ti = 10, controllerType = Modelica.Blocks.Types.SimpleController.P, k = 1, limitsAtInit = true, yMax = 40) annotation(
        Placement(visible = true, transformation(origin = {354, 658}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression realExpression2(y = 12e6) annotation(
        Placement(visible = true, transformation(origin = {282, 656}, extent = {{-44, -18}, {44, 18}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression realExpression4(y = s43_CO2.medium.p) annotation(
        Placement(visible = true, transformation(origin = {336, 542}, extent = {{-44, -18}, {44, 18}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_production24(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-840, 686}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_production28(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-838, 528}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_production29(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-722, 430}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_production37(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-596, 810}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_production38(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-696, 614}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_production31(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-680, 518}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Fluid.Sources.MassFlowSource_T CO2_production25(redeclare package Medium = Medium_CO2, T = 300, m_flow = 0, nPorts = 1, use_m_flow_in = true) annotation(
        Placement(visible = true, transformation(origin = {-840, 626}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression CO2_production_24_function(y = 0.225 * triggeredTrapezoid24.y) annotation(
        Placement(visible = true, transformation(origin = {-914, 690}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression CO2_production_28_function(y = 0.214 * triggeredTrapezoid28.y) annotation(
        Placement(visible = true, transformation(origin = {-886, 528}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression CO2_production_29_function(y = 0.43 * triggeredTrapezoid29.y) annotation(
        Placement(visible = true, transformation(origin = {-764, 434}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression CO2_production_37_function(y = 0.225 * triggeredTrapezoid37.y) annotation(
        Placement(visible = true, transformation(origin = {-636, 818}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression CO2_production_38_function(y = 0.3 * triggeredTrapezoid38.y) annotation(
        Placement(visible = true, transformation(origin = {-730, 614}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression CO2_production_31_function(y = 0.214 * triggeredTrapezoid31.y) annotation(
        Placement(visible = true, transformation(origin = {-714, 516}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Sources.RealExpression CO2_production_25_function(y = 0.225 * triggeredTrapezoid25.y) annotation(
        Placement(visible = true, transformation(origin = {-908, 636}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid28b(amplitude = 14.282 / 2, falling = 6 *3600, offset = 0, rising = 6 *3600) annotation(
        Placement(visible = true, transformation(origin = {-370.16, -472.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
    Modelica.Blocks.Logical.OnOffController onOffController28b(bandwidth = 8e6) annotation(
        Placement(visible = true, transformation(origin = {-362.16, -472.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
    Modelica.Blocks.Math.Add add28 annotation(
        Placement(visible = true, transformation(origin = {-379, -457}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
    Modelica.Blocks.Logical.OnOffController onOffController38b(bandwidth = 8e6) annotation(
        Placement(visible = true, transformation(origin = {167.62, -543.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
    Modelica.Blocks.Logical.TriggeredTrapezoid triggeredTrapezoid38b(amplitude = 12.853 / 2, falling = 3600, offset = 0, rising = 3600) annotation(
        Placement(visible = true, transformation(origin = {159.62, -543.79}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
    Modelica.Blocks.Math.Add add annotation(
        Placement(visible = true, transformation(origin = {150, -532}, extent = {{2, -2}, {-2, 2}}, rotation = 0)));
    Modelica.Blocks.Nonlinear.FixedDelay fixedDelay(delayTime = 3600)  annotation(
        Placement(visible = true, transformation(origin = {-331, -477}, extent = {{3, -3}, {-3, 3}}, rotation = 0)));
    equation
      totalDemand = totalH2Demand19.y + totalH2Demand22.y + totalH2Demand23.y + totalH2Demand24.y + totalH2Demand25.y + totalH2Demand28.y + totalH2Demand29.y + totalH2Demand30.y + totalH2Demand31.y + totalH2Demand37.y + totalH2Demand38.y + totalH2Demand39.y + H2_production_24.m_flow_in + H2_production_25.m_flow_in + H2_production_28.m_flow_in + H2_production_29.m_flow_in + H2_production_31.m_flow_in + H2_production_37.m_flow_in + H2_production_38.m_flow_in;
// CONNECT HEAT PORTS TO FIXED TEMPERATURE
      connect(fixedTemperature.port, s37.heatPort);
      connect(fixedTemperature.port, s38.heatPort);
      connect(fixedTemperature.port, s39.heatPort);
      connect(fixedTemperature.port, s19.heatPort);
      connect(fixedTemperature.port, s22.heatPort);
      connect(fixedTemperature.port, s23.heatPort);
      connect(fixedTemperature.port, s24.heatPort);
      connect(fixedTemperature.port, s25.heatPort);
      connect(fixedTemperature.port, s28.heatPort);
      connect(fixedTemperature.port, s29.heatPort);
      connect(fixedTemperature.port, s30.heatPort);
      connect(fixedTemperature.port, s31.heatPort);
      connect(fixedTemperature.port, storage1.heatPort);
      for i in 1:pipe_24_19.nNodes loop
        connect(fixedTemperature.port, pipe_24_19.heatPorts[i]);
      end for;
      for i in 1:pipe_24_30.nNodes loop
        connect(fixedTemperature.port, pipe_24_30.heatPorts[i]);
      end for;
      for i in 1:pipe_25_30.nNodes loop
        connect(fixedTemperature.port, pipe_25_30.heatPorts[i]);
      end for;
      for i in 1:pipe_25_31.nNodes loop
        connect(fixedTemperature.port, pipe_25_31.heatPorts[i]);
      end for;
      for i in 1:pipe_28_22.nNodes loop
        connect(fixedTemperature.port, pipe_28_22.heatPorts[i]);
      end for;
      for i in 1:pipe_28_23.nNodes loop
        connect(fixedTemperature.port, pipe_28_23.heatPorts[i]);
      end for;
      for i in 1:pipe_28_29.nNodes loop
        connect(fixedTemperature.port, pipe_28_29.heatPorts[i]);
      end for;
      for i in 1:pipe_29_37.nNodes loop
        connect(fixedTemperature.port, pipe_29_37.heatPorts[i]);
      end for;
      for i in 1:pipe_31_37.nNodes loop
        connect(fixedTemperature.port, pipe_31_37.heatPorts[i]);
      end for;
      for i in 1:pipe_38_37.nNodes loop
        connect(fixedTemperature.port, pipe_38_37.heatPorts[i]);
      end for;
      for i in 1:pipe_38_39.nNodes loop
        connect(fixedTemperature.port, pipe_38_39.heatPorts[i]);
      end for;
      for i in 1:pipe_CO2_22_23.nNodes loop
        connect(fixedTemperature.port, pipe_CO2_22_23.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_23_24.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_23_28.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_24_25.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_25_41.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_28_29.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_29_24.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_30_31.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_30_37.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_31_41.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_37_38.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_38_39.heatPorts[i]);
        connect(fixedTemperature.port, pipe_CO2_39_43.heatPorts[i]);
      end for;
// CONNECT PIPES BETWEEN CELL VOLUMES
      connect(s24.ports[1], pipe_24_19.port_a) annotation(
        Line(points = {{-109, 39}, {-44, 226}}, color = {0, 127, 255}));
      connect(s19.ports[1], pipe_24_19.port_b) annotation(
        Line(points = {{21, 413}, {-44, 226}}, color = {0, 127, 255}));
      connect(s24.ports[2], pipe_24_30.port_a) annotation(
        Line(points = {{-109, 39}, {-96, -137}}, color = {0, 127, 255}));
      connect(s30.ports[1], pipe_24_30.port_b) annotation(
        Line(points = {{-84, -312}, {-96, -137}}, color = {0, 127, 255}));
      connect(s25.ports[1], pipe_25_30.port_a) annotation(
        Line(points = {{40, 79}, {-22, -116}}, color = {0, 127, 255}));
      connect(s30.ports[2], pipe_25_30.port_b) annotation(
        Line(points = {{-84, -312}, {-22, -116}}, color = {0, 127, 255}));
      connect(s25.ports[2], pipe_25_31.port_a) annotation(
        Line(points = {{40, 79}, {62, -93}}, color = {0, 127, 255}));
      connect(s31.ports[1], pipe_25_31.port_b) annotation(
        Line(points = {{84, -266}, {62, -93}}, color = {0, 127, 255}));
      connect(s28.ports[1], pipe_28_22.port_a) annotation(
        Line(points = {{-422, -418}, {-436, -243}}, color = {0, 127, 255}));
      connect(s22.ports[1], pipe_28_22.port_b) annotation(
        Line(points = {{-449, -68}, {-436, -243}}, color = {0, 127, 255}));
      connect(s28.ports[2], pipe_28_23.port_a) annotation(
        Line(points = {{-422, -418}, {-351, -216}}, color = {0, 127, 255}));
      connect(s23.ports[1], pipe_28_23.port_b) annotation(
        Line(points = {{-279, -14}, {-351, -216}}, color = {0, 127, 255}));
      connect(s28.ports[3], pipe_28_29.port_a) annotation(
        Line(points = {{-422, -418}, {-338, -391}}, color = {0, 127, 255}));
      connect(s29.ports[1], pipe_28_29.port_b) annotation(
        Line(points = {{-253, -364}, {-338, -391}}, color = {0, 127, 255}));
      connect(s29.ports[2], pipe_29_37.port_a) annotation(
        Line(points = {{-253, -364}, {-163, -490}}, color = {0, 127, 255}));
      connect(s37.ports[1], pipe_29_37.port_b) annotation(
        Line(points = {{-72, -617}, {-163, -490}}, color = {0, 127, 255}));
      connect(s31.ports[2], pipe_31_37.port_a) annotation(
        Line(points = {{84, -266}, {6, -441}}, color = {0, 127, 255}));
      connect(s37.ports[2], pipe_31_37.port_b) annotation(
        Line(points = {{-72, -617}, {6, -441}}, color = {0, 127, 255}));
      connect(s38.ports[1], pipe_38_37.port_a) annotation(
        Line(points = {{108, -489}, {18, -553}}, color = {0, 127, 255}));
      connect(s37.ports[3], pipe_38_37.port_b) annotation(
        Line(points = {{-72, -617}, {18, -553}}, color = {0, 127, 255}));
      connect(s38.ports[2], pipe_38_39.port_a) annotation(
        Line(points = {{108, -489}, {166, -474}}, color = {0, 127, 255}));
      connect(s39.ports[1], pipe_38_39.port_b) annotation(
        Line(points = {{225, -459}, {166, -474}}, color = {0, 127, 255}));
// CONNECT PRODUCTION TO STORAGE VOLUMES
      connect(H2_production_37.ports[1], s37.ports[4]) annotation(
        Line(points = {{-72, -616}, {-50, -661}}, color = {0, 127, 255}));
      connect(H2_production_38.ports[1], s38.ports[3]) annotation(
        Line(points = {{107, -488}, {129, -533}}, color = {0, 127, 255}));
      connect(H2_production_24.ports[1], s24.ports[3]) annotation(
        Line(points = {{-109, 38}, {-87, -6}}, color = {0, 127, 255}));
      connect(H2_production_25.ports[1], s25.ports[3]) annotation(
        Line(points = {{40, 79}, {62, 34}}, color = {0, 127, 255}));
      connect(H2_production_28.ports[1], s28.ports[4]) annotation(
        Line(points = {{-422, -417}, {-400, -462}}, color = {0, 127, 255}));
      connect(H2_production_29.ports[1], s29.ports[3]) annotation(
        Line(points = {{-253, -363}, {-231, -408}}, color = {0, 127, 255}));
      connect(H2_production_31.ports[1], s31.ports[3]) annotation(
        Line(points = {{83, -265}, {105, -310}}, color = {0, 127, 255}));
// CONTROL PRODUCTION WITH PRESSURE SETPOINT
      connect(PressureSetPoint37.y, onOffController37.reference);
      connect(pressure_signal37.y, onOffController37.u);
      connect(onOffController37.y, triggeredTrapezoid37.u);
      connect(triggeredTrapezoid37.y, H2_production_37.m_flow_in);
      connect(PressureSetPoint38.y, onOffController38.reference);
//connect(pressure_signal38.y, onOffController38.u) annotation(
//  Line);
      connect(onOffController38.y, triggeredTrapezoid38.u);
// connect(triggeredTrapezoid38.y, H2_production_38.m_flow_in);
      connect(PressureSetPoint24.y, onOffController24.reference);
      connect(pressure_signal24.y, onOffController24.u) annotation(
        Line);
      connect(onOffController24.y, triggeredTrapezoid24.u);
      connect(triggeredTrapezoid24.y, H2_production_24.m_flow_in);
      connect(PressureSetPoint25.y, onOffController25.reference);
      connect(pressure_signal25.y, onOffController25.u);
      connect(onOffController25.y, triggeredTrapezoid25.u);
      connect(triggeredTrapezoid25.y, H2_production_25.m_flow_in);
    connect(PressureSetPoint28.y, onOffController28.reference) annotation(
        Line);
//connect(pressure_signal28.y, onOffController28.u) annotation(
//    Line);
      connect(onOffController28.y, triggeredTrapezoid28.u);
//connect(triggeredTrapezoid28.y, H2_production_28.m_flow_in);
      connect(PressureSetPoint29.y, onOffController29.reference);
      connect(pressure_signal29.y, onOffController29.u);
      connect(onOffController29.y, triggeredTrapezoid29.u);
      connect(triggeredTrapezoid29.y, H2_production_29.m_flow_in);
      connect(PressureSetPoint31.y, onOffController31.reference);
      connect(pressure_signal31.y, onOffController31.u);
      connect(onOffController31.y, triggeredTrapezoid31.u);
      connect(triggeredTrapezoid31.y, H2_production_31.m_flow_in);
// DOMESTIC DEMAND
      connect(t_s.y, normalizedDomesticDemand.u);
// CONNECT DEMAND TO STORAGE
      connect(H2_demand_37.ports[1], s37.ports[5]);
      connect(H2_demand_38.ports[1], s38.ports[4]);
      connect(H2_demand_39.ports[1], s39.ports[3]);
      connect(H2_demand_19.ports[1], s19.ports[3]);
      connect(H2_demand_22.ports[1], s22.ports[3]);
      connect(H2_demand_23.ports[1], s23.ports[3]);
      connect(H2_demand_24.ports[1], s24.ports[4]);
      connect(H2_demand_25.ports[1], s25.ports[4]);
      connect(H2_demand_28.ports[1], s28.ports[5]);
      connect(H2_demand_29.ports[1], s29.ports[4]);
      connect(H2_demand_30.ports[1], s30.ports[4]);
      connect(H2_demand_31.ports[1], s31.ports[4]);
      connect(totalH2Demand37.y, H2_demand_37.m_flow_in);
      connect(totalH2Demand38.y, H2_demand_38.m_flow_in);
      connect(totalH2Demand39.y, H2_demand_39.m_flow_in);
      connect(totalH2Demand19.y, H2_demand_19.m_flow_in);
      connect(totalH2Demand22.y, H2_demand_22.m_flow_in);
      connect(totalH2Demand23.y, H2_demand_23.m_flow_in) annotation(
        Line);
      connect(totalH2Demand24.y, H2_demand_24.m_flow_in);
      connect(totalH2Demand25.y, H2_demand_25.m_flow_in);
      connect(totalH2Demand28.y, H2_demand_28.m_flow_in);
      connect(totalH2Demand29.y, H2_demand_29.m_flow_in);
      connect(totalH2Demand30.y, H2_demand_30.m_flow_in);
      connect(totalH2Demand31.y, H2_demand_31.m_flow_in);
      connect(from_storage.ports[1], s25.ports[5]) annotation(
        Line(points = {{124, 46}, {40, 46}, {40, 60}, {40, 60}}, color = {0, 127, 255}));
      connect(to_storage.ports[1], storage1.ports[1]) annotation(
        Line(points = {{122, 112}, {118, 112}, {118, 156}, {122, 156}}, color = {0, 127, 255}));
      connect(gainin.y, to_storage.m_flow_in) annotation(
        Line(points = {{152, 112}, {142, 112}, {142, 120}, {142, 120}}, color = {0, 0, 127}));
      connect(gain.y, from_storage.m_flow_in) annotation(
        Line(points = {{162, 62}, {144, 62}, {144, 54}, {144, 54}}, color = {0, 0, 127}));
      connect(realExpression.y, onOffController.u) annotation(
        Line(points = {{213, 145}, {212, 145}, {212, 148}}, color = {0, 0, 127}));
      connect(constant1.y, onOffController.reference) annotation(
        Line(points = {{214, 155}, {214, 150.5}, {212, 150.5}, {212, 152}}, color = {0, 0, 127}));
      connect(onOffController.y, triggeredTrapezoid.u) annotation(
        Line(points = {{205, 150}, {204, 150}}, color = {255, 0, 255}));
      connect(storage_pressure1.y, storage_control1.storage_pressure) annotation(
        Line(points = {{202, 110}, {194, 110}, {194, 94}, {194, 94}}, color = {0, 0, 127}));
      connect(realExpression3.y, pid.u_s) annotation(
        Line(points = {{214, -50}, {228, -50}, {228, -48}, {228, -48}}, color = {0, 0, 127}));
      connect(realExpression1.y, pid.u_m) annotation(
        Line(points = {{214, -102}, {240, -102}, {240, -60}, {240, -60}}, color = {0, 0, 127}));
      connect(pid.y, storage_control1.makeup_flow) annotation(
        Line(points = {{252, -48}, {206, -48}, {206, 94}, {208, 94}}, color = {0, 0, 127}));
      connect(storage_control1.storage_flow, firstOrder.u) annotation(
        Line(points = {{202, 76}, {200, 76}, {200, 40}, {200, 40}}, color = {0, 0, 127}));
      connect(firstOrder.y, gain.u) annotation(
        Line(points = {{176, 40}, {174, 40}, {174, 62}, {174, 62}}, color = {0, 0, 127}));
      connect(firstOrder.y, gainin.u) annotation(
        Line(points = {{176, 40}, {164, 40}, {164, 112}, {164, 112}}, color = {0, 0, 127}));
// CO2 piping
      connect(fixedTemperature.port, s22_CO2.heatPort);
      connect(fixedTemperature.port, s23_CO2.heatPort);
      connect(fixedTemperature.port, s24_CO2.heatPort);
      connect(fixedTemperature.port, s25_CO2.heatPort);
      connect(fixedTemperature.port, s28_CO2.heatPort);
      connect(fixedTemperature.port, s43_CO2.heatPort) annotation(
        Line);
      connect(fixedTemperature.port, s39_CO2.heatPort);
      connect(fixedTemperature.port, s41_CO2.heatPort) annotation(
        Line);
      connect(fixedTemperature.port, s38_CO2.heatPort);
      connect(fixedTemperature.port, s31_CO2.heatPort);
      connect(fixedTemperature.port, s29_CO2.heatPort);
      connect(fixedTemperature.port, s37_CO2.heatPort);
      connect(fixedTemperature.port, s30_CO2.heatPort);
      connect(pressure_co2_end.y, PID_injection.u_m) annotation(
        Line(points = {{352, 736}, {274, 736}, {274, 810}}, color = {0, 0, 127}));
      connect(co2SetPoint.y, PID_injection.u_s) annotation(
        Line(points = {{238, 822}, {262, 822}}, color = {0, 0, 127}));
      connect(s22_CO2.ports[1], pipe_CO2_22_23.port_a);
      connect(s23_CO2.ports[1], pipe_CO2_22_23.port_b);
      connect(s23_CO2.ports[2], pipe_CO2_23_24.port_a);
      connect(s24_CO2.ports[1], pipe_CO2_23_24.port_b);
      connect(s23_CO2.ports[3], pipe_CO2_23_28.port_a);
// s23 3 ports
      connect(s28_CO2.ports[1], pipe_CO2_23_28.port_b);
      connect(s24_CO2.ports[2], pipe_CO2_24_25.port_a);
      connect(s25_CO2.ports[1], pipe_CO2_24_25.port_b);
      connect(s25_CO2.ports[2], pipe_CO2_25_41.port_a);
// s25 2 ports
      connect(s41_CO2.ports[1], pipe_CO2_25_41.port_b);
      connect(s28_CO2.ports[2], pipe_CO2_28_29.port_a);
// s28 2 ports
      connect(s29_CO2.ports[1], pipe_CO2_28_29.port_b);
      connect(s29_CO2.ports[2], pipe_CO2_29_24.port_a);
// s29 2 ports
      connect(s24_CO2.ports[3], pipe_CO2_29_24.port_b);
//s24 3 ports
      connect(s30_CO2.ports[1], pipe_CO2_30_31.port_a);
      connect(s31_CO2.ports[1], pipe_CO2_30_31.port_b);
      connect(s30_CO2.ports[2], pipe_CO2_30_37.port_a);
// s30 2 ports
      connect(s37_CO2.ports[1], pipe_CO2_30_37.port_b);
      connect(s31_CO2.ports[2], pipe_CO2_31_41.port_a);
// s31 2 ports
      connect(s41_CO2.ports[2], pipe_CO2_31_41.port_b);
      connect(s37_CO2.ports[2], pipe_CO2_37_38.port_a);
//s37 2 ports
      connect(s38_CO2.ports[1], pipe_CO2_37_38.port_b);
      connect(s38_CO2.ports[2], pipe_CO2_38_39.port_a);
//s38 2 ports
      connect(s39_CO2.ports[1], pipe_CO2_38_39.port_b);
      connect(s39_CO2.ports[2], pipe_CO2_39_43.port_a);
//s39 2 ports
      connect(s43_CO2.ports[1], pipe_CO2_39_43.port_b);
      connect(CO2_to_storage2.ports[1], s43_CO2.ports[2]) annotation(
        Line(points = {{292, 600}, {228, 600}, {228, 596}, {236, 596}}));
      connect(PID_injection.y, CO2_to_storage.m_flow_in) annotation(
        Line(points = {{286, 822}, {232, 822}, {232, 690}, {232, 690}}, color = {0, 0, 127}));
      connect(realExpression2.y, PID.u_s) annotation(
        Line(points = {{330, 656}, {342, 656}, {342, 658}, {342, 658}}, color = {0, 0, 127}));
      connect(realExpression4.y, PID.u_m) annotation(
        Line(points = {{384, 542}, {352, 542}, {352, 646}, {354, 646}}, color = {0, 0, 127}));
      connect(PID.y, CO2_to_storage2.m_flow_in) annotation(
        Line(points = {{366, 658}, {380, 658}, {380, 608}, {312, 608}, {312, 608}}, color = {0, 0, 127}));
      connect(CO2_production24.ports[1], s24_CO2.ports[4]) annotation(
        Line(points = {{-830, 686}, {-786, 686}, {-786, 670}, {-780, 670}}, color = {0, 127, 255}));
      connect(CO2_production_24_function.y, CO2_production24.m_flow_in) annotation(
        Line(points = {{-902, 690}, {-875, 690}, {-875, 694}, {-850, 694}}, color = {0, 0, 127}));
      connect(CO2_production_38_function.y, CO2_production38.m_flow_in) annotation(
        Line(points = {{-718, 614}, {-708, 614}, {-708, 622}, {-706, 622}}, color = {0, 0, 127}));
      connect(CO2_production38.ports[1], s38_CO2.ports[3]) annotation(
        Line(points = {{-686, 614}, {-662, 614}, {-662, 596}, {-656, 596}}, color = {0, 127, 255}));
      connect(CO2_production_25_function.y, CO2_production25.m_flow_in) annotation(
        Line(points = {{-896, 636}, {-848, 636}, {-848, 634}, {-850, 634}}, color = {0, 0, 127}));
      connect(CO2_production25.ports[1], s25_CO2.ports[3]) annotation(
        Line(points = {{-830, 626}, {-794, 626}, {-794, 606}, {-786, 606}}, color = {0, 127, 255}));
      connect(CO2_production_28_function.y, CO2_production28.m_flow_in) annotation(
        Line(points = {{-874, 528}, {-848, 528}, {-848, 536}, {-848, 536}}, color = {0, 0, 127}));
      connect(CO2_production28.ports[1], s28_CO2.ports[3]) annotation(
        Line(points = {{-828, 528}, {-780, 528}, {-780, 542}, {-774, 542}}));
      connect(CO2_production_31_function.y, CO2_production31.m_flow_in) annotation(
        Line(points = {{-702, 516}, {-690, 516}, {-690, 526}, {-690, 526}}, color = {0, 0, 127}));
      connect(CO2_production31.ports[1], s31_CO2.ports[3]) annotation(
        Line(points = {{-670, 518}, {-640, 518}, {-640, 502}, {-634, 502}}, color = {0, 127, 255}));
      connect(CO2_production_29_function.y, CO2_production29.m_flow_in) annotation(
        Line(points = {{-752, 434}, {-734, 434}, {-734, 438}, {-732, 438}}, color = {0, 0, 127}));
      connect(CO2_production29.ports[1], s29_CO2.ports[3]) annotation(
        Line(points = {{-712, 430}, {-662, 430}, {-662, 418}, {-656, 418}}, color = {0, 127, 255}));
      connect(CO2_production_37_function.y, CO2_production37.m_flow_in) annotation(
        Line(points = {{-624, 818}, {-606, 818}, {-606, 818}, {-606, 818}}, color = {0, 0, 127}));
      connect(CO2_production37.ports[1], s37_CO2.ports[3]) annotation(
        Line(points = {{-586, 810}, {-558, 810}, {-558, 798}, {-552, 798}}, color = {0, 127, 255}));
      connect(CO2_to_storage.ports[1], s41_CO2.ports[3]) annotation(
        Line(points = {{212, 682}, {98, 682}, {98, 714}, {100, 714}}, color = {0, 127, 255}));
    connect(onOffController28b.y, triggeredTrapezoid28b.u) annotation(
        Line(points = {{-366, -472}, {-366, -472}, {-366, -472}, {-366, -472}}, color = {255, 0, 255}));
    connect(PressureSetPoint28.y, onOffController28b.reference) annotation(
        Line(points = {{-348, -452}, {-348, -470}, {-358, -470}}, color = {0, 0, 127}));
    connect(triggeredTrapezoid28b.y, add28.u2) annotation(
        Line(points = {{-374, -472}, {-376, -472}, {-376, -458}, {-376, -458}}, color = {0, 0, 127}));
    connect(triggeredTrapezoid28.y, add28.u1) annotation(
        Line(points = {{-374, -462}, {-374, -462}, {-374, -456}, {-376, -456}}, color = {0, 0, 127}));
    connect(add28.y, H2_production_28.m_flow_in) annotation(
        Line(points = {{-382, -456}, {-390, -456}, {-390, -454}, {-390, -454}}, color = {0, 0, 127}));
    connect(onOffController38b.y, triggeredTrapezoid38b.u) annotation(
        Line(points = {{164, -544}, {164, -544}, {164, -544}, {164, -544}}, color = {255, 0, 255}));
    connect(PressureSetPoint38.y, onOffController38b.reference) annotation(
        Line(points = {{174, -528}, {172, -528}, {172, -542}, {172, -542}}, color = {0, 0, 127}));
    connect(triggeredTrapezoid38b.y, add.u2) annotation(
        Line(points = {{156, -544}, {152, -544}, {152, -534}, {152, -534}}, color = {0, 0, 127}));
    connect(triggeredTrapezoid38.y, add.u1) annotation(
        Line(points = {{156, -534}, {152, -534}, {152, -530}, {152, -530}}, color = {0, 0, 127}));
    connect(add.y, H2_production_38.m_flow_in) annotation(
        Line(points = {{148, -532}, {140, -532}, {140, -524}, {140, -524}}, color = {0, 0, 127}));
    connect(pressure_signal38.y, onOffController38.u) annotation(
        Line(points = {{194, -542}, {172, -542}, {172, -536}, {172, -536}}, color = {0, 0, 127}));
    connect(pressure_signal38.y, onOffController38b.u) annotation(
        Line(points = {{194, -542}, {172, -542}, {172, -546}, {172, -546}}, color = {0, 0, 127}));
    connect(pressure_signal28.y, fixedDelay.u) annotation(
        Line(points = {{-318, -474}, {-328, -474}, {-328, -476}, {-328, -476}}, color = {0, 0, 127}));
    connect(fixedDelay.y, onOffController28b.u) annotation(
        Line(points = {{-334, -476}, {-358, -476}, {-358, -474}, {-358, -474}}, color = {0, 0, 127}));
    connect(fixedDelay.y, onOffController28.u) annotation(
        Line(points = {{-334, -476}, {-358, -476}, {-358, -464}, {-358, -464}}, color = {0, 0, 127}));
      annotation(
        Diagram(coordinateSystem(extent = {{-1000, -1000}, {1000, 1000}}, initialScale = 0.1)),
        Icon(coordinateSystem(extent = {{-1000, -1000}, {1000, 1000}})));
    
    end Humber_Region_CaseStudy;

    model H2_pipe_compression
  replaceable package Medium = H2;
      extends Modelica.Icons.Example;
      Operational_Toolkit_v2.Pipe_IdealHeatTransfer pipe(redeclare package Medium = Medium, diameter = 200e-3, energyDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial, length = 100e3, massDynamics = Modelica.Fluid.Types.Dynamics.SteadyStateInitial,  modelStructure = Modelica.Fluid.Types.ModelStructure.av_b, momentumDynamics = Modelica.Fluid.Types.Dynamics.SteadyState, nNodes = 10, p_a_start = 5e6, p_b_start = 5e6, roughness = 4.5e-05, use_HeatTransfer = true) annotation(
        Placement(visible = true, transformation(origin = {14, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Boundary_pT boundary_pT(redeclare package Medium = Medium, T = 280, nPorts = 1, p = 5e6) annotation(
        Placement(visible = true, transformation(origin = {-70, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Operational_Toolkit_v2.Compressor_isentropic compressor_isentropic(redeclare package Medium = Medium) annotation(
        Placement(visible = true, transformation(origin = {-62, -66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      Operational_Toolkit_v2.Boundary_pT sink_pT(redeclare package Medium = Medium, T = 280, nPorts = 1, p = 4.8e6) annotation(
        Placement(visible = true, transformation(origin = {98, 2}, extent = {{10, -10}, {-10, 10}}, rotation = 0)));
      FixedTemperature fixedTemperature(T = 280) annotation(
        Placement(visible = true, transformation(origin = {6, 34}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
      inner System system annotation(
        Placement(visible = true, transformation(origin = {-90, 88}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Fluid.Sensors.MassFlowRate massFlowRate(redeclare package Medium = Medium) annotation(
        Placement(visible = true, transformation(origin = {54, 0}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Blocks.Continuous.LimPID pid( Ti = 1000,controllerType = Modelica.Blocks.Types.SimpleController.PI, k = 0.1, limitsAtInit = true, yMax = 1.3, yMin = 1, y_start = 1)  annotation(
        Placement(visible = true, transformation(origin = {-44, 44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Blocks.Sources.Step massflow_step(height = 1, offset = 2, startTime = 2e4)  annotation(
        Placement(visible = true, transformation(origin = {-80, 44}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Operational_Toolkit_v2.Compressor_isentropic compressor_isentropic1(redeclare package Medium = Medium) annotation(
        Placement(visible = true, transformation(origin = {-4, -66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Operational_Toolkit_v2.Compressor_isentropic compressor_isentropic2(redeclare package Medium = Medium) annotation(
        Placement(visible = true, transformation(origin = {50, -64}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Operational_Toolkit_v2.ClosedVolume closedVolume(redeclare package Medium = Medium, V = 1, p_start = 5e6, use_HeatTransfer = true, use_portsData = false, nPorts = 2) annotation(
        Placement(visible = true, transformation(origin = {-34, -66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Operational_Toolkit_v2.ClosedVolume closedVolume1(redeclare package Medium = Medium, V = 1, p_start = 5e6, use_HeatTransfer = true, use_portsData = false, nPorts = 2) annotation(
        Placement(visible = true, transformation(origin = {24, -66}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
    equation
      for i in 1:pipe.nNodes loop
        connect(fixedTemperature.port, pipe.heatPorts[i]);
      end for;
      connect(fixedTemperature.port, pipe.heatPorts[1]) annotation(
        Line(points = {{16, 34}, {14, 34}, {14, 4}, {14, 4}}, color = {191, 0, 0}));
      connect(pipe.port_b, massFlowRate.port_a) annotation(
        Line(points = {{24, 0}, {44, 0}, {44, 0}, {44, 0}}, color = {0, 127, 255}));
      connect(massFlowRate.port_b, sink_pT.ports[1]) annotation(
        Line(points = {{64, 0}, {88, 0}, {88, 2}, {88, 2}}, color = {0, 127, 255}));
      connect(massFlowRate.m_flow, pid.u_m) annotation(
        Line(points = {{54, 12}, {54, 12}, {54, 62}, {-20, 62}, {-20, 22}, {-46, 22}, {-46, 32}, {-44, 32}}, color = {0, 0, 127}));
  connect(massflow_step.y, pid.u_s) annotation(
        Line(points = {{-68, 44}, {-56, 44}, {-56, 44}, {-56, 44}}, color = {0, 0, 127}));
  connect(compressor_isentropic.port_b, closedVolume.ports[1]) annotation(
        Line(points = {{-52, -66}, {-34, -66}, {-34, -76}, {-34, -76}}, color = {0, 127, 255}));
  connect(closedVolume.ports[2], compressor_isentropic1.port_a) annotation(
        Line(points = {{-34, -76}, {-14, -76}, {-14, -66}, {-14, -66}}, color = {0, 127, 255}));
  connect(compressor_isentropic1.port_b, closedVolume1.ports[1]) annotation(
        Line(points = {{6, -66}, {22, -66}, {22, -76}, {24, -76}}, color = {0, 127, 255}));
  connect(closedVolume1.ports[2], compressor_isentropic2.port_a) annotation(
        Line(points = {{24, -76}, {40, -76}, {40, -64}, {40, -64}}, color = {0, 127, 255}));
  connect(boundary_pT.ports[1], compressor_isentropic.port_a) annotation(
        Line(points = {{-60, 0}, {-56, 0}, {-56, -28}, {-84, -28}, {-84, -66}, {-72, -66}, {-72, -66}}, color = {0, 127, 255}));
  connect(fixedTemperature.port, closedVolume.heatPort) annotation(
        Line(points = {{16, 34}, {-18, 34}, {-18, -22}, {-44, -22}, {-44, -66}, {-44, -66}}, color = {191, 0, 0}));
  connect(fixedTemperature.port, closedVolume1.heatPort) annotation(
        Line(points = {{16, 34}, {34, 34}, {34, -38}, {14, -38}, {14, -66}, {14, -66}}, color = {191, 0, 0}));
  connect(pid.y, compressor_isentropic.P_ratio) annotation(
        Line(points = {{-32, 44}, {-26, 44}, {-26, -40}, {-72, -40}, {-72, -54}, {-72, -54}}, color = {0, 0, 127}));
  connect(pid.y, compressor_isentropic2.P_ratio) annotation(
        Line(points = {{-32, 44}, {-22, 44}, {-22, -42}, {40, -42}, {40, -52}, {40, -52}, {40, -52}}, color = {0, 0, 127}));
  connect(pid.y, compressor_isentropic1.P_ratio) annotation(
        Line(points = {{-32, 44}, {-34, 44}, {-34, -34}, {-14, -34}, {-14, -54}, {-14, -54}}, color = {0, 0, 127}));
  connect(compressor_isentropic2.port_b, pipe.port_a) annotation(
        Line(points = {{60, -64}, {60, -64}, {60, -28}, {-14, -28}, {-14, 0}, {4, 0}, {4, 0}}, color = {0, 127, 255}));
    end H2_pipe_compression;
    annotation(
      preferredView = "info",
      Documentation(info = "<html><head></head><body>Package with some examples of how to use the operational toolkit<div><br></div></body></html>"));
  end Examples;

  model Ramp
    extends Modelica.Blocks.Sources.Ramp;
  equation

  end Ramp;

  model H2_custom
    extends Modelica.Media.Interfaces.PartialPureSubstance(ThermoStates = Modelica.Media.Interfaces.Choices.IndependentVariables.pTX, singleState = true, Temperature(min = 100, max = 500, start = 300, nominal = 300), AbsolutePressure(min = 1e6, max = 100e6, nominal = 6e6), p_default = 6e6, T_default = 300);
    //min = 273.15, max = 303.15
    constant MolarMass MM_const = 2.016e-3 "Molar mass";
    // kg/mol

    redeclare record ThermodynamicState "A selection of variables that uniquely defines the thermodynamic state"
      extends Modelica.Icons.Record;
      AbsolutePressure p "Absolute pressure of medium";
      Temperature T "Temperature of medium";
    end ThermodynamicState;
  
    redeclare model extends BaseProperties(T(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default), p(stateSelect = if preferredMediumStates then StateSelect.prefer else StateSelect.default, nominal = 6e6)) "Base properties of medium"
        Real Pr, Tr;
  
      equation
        Pr = (p * 1e-6 - 1) / (40 - 1);
        Tr = (T - 273.15) / (303.15 - 273.15);
//d = p/R/T;
        d = MM * (437.0214 + Pr ^ 1.0 * 16981.67 + Pr ^ 2.0 * (-4197.979) + Pr ^ 3.0 * 570.4742 + Pr ^ 4.0 * 33.92531 + Tr ^ 1.0 * (-48.97457) + Tr ^ 1.0 * Pr ^ 1.0 * (-1859.952) + Tr ^ 1.0 * Pr ^ 2.0 * 803.5669 + Tr ^ 1.0 * Pr ^ 3.0 * (-127.3914) + Tr ^ 2.0 * 8.82671 + Tr ^ 2.0 * Pr ^ 1.0 * 180.9694 + Tr ^ 2.0 * Pr ^ 2.0 * (-74.76895) + Tr ^ 3.0 * (-2.41459) + Tr ^ 3.0 * Pr ^ 1.0 * (-8.553919));
        h = (7214.099 + Pr ^ 1.0 * 278.1949 + Pr ^ 2.0 * 197.3857 + Pr ^ 3.0 * (-46.06233) + Pr ^ 4.0 * (-1.962117) + Tr ^ 1.0 * 861.0746 + Tr ^ 1.0 * Pr ^ 1.0 * 75.43346 + Tr ^ 1.0 * Pr ^ 2.0 * (-49.11461) + Tr ^ 1.0 * Pr ^ 3.0 * 13.45874 + Tr ^ 2.0 * 3.483872 + Tr ^ 2.0 * Pr ^ 1.0 * (-5.284725) + Tr ^ 2.0 * Pr ^ 2.0 * 2.367275) / MM;
        u = h - p / d;
        p = state.p;
        T = state.T;
        MM = MM_const;
        R = 8.3144 / MM;
    end BaseProperties;
  
    redeclare function extends setState_pTX "Set the thermodynamic state record from p and T (X not needed)"
      algorithm
        state := ThermodynamicState(p = p, T = T);
    end setState_pTX;
  
// redeclare function extends setState_phX "Set the thermodynamic state record from p and h (X not needed)"
    // protected
    //algorithm
    // state := ThermodynamicState(p = p, T = 273.1499 + ((p * 1e-6 - 1) / (0 - 1)) ^ 1.0 * (-9.718425) + ((p * 1e-6 - 1) / (0 - 1)) ^ 2.0 * (-5.885205) + ((p * 1e-6 - 1) / (0 - 1)) ^ 3.0 * 1.234185 + ((p * 1e-6 - 1) / (0 - 1)) ^ 4.0 * 0.1204419 + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 1.0 * 46.29614 + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 1.0 * ((p * 1e-6 - 1) / (0 - 1)) ^ 1.0 * (-3.869206) + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 1.0 * ((p * 1e-6 - 1) / (0 - 1)) ^ 2.0 * 2.530362 + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 1.0 * ((p * 1e-6 - 1) / (0 - 1)) ^ 3.0 * (-0.6476876) + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 2.0 * (-0.3000331) + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 2.0 * ((p * 1e-6 - 1) / (0 - 1)) ^ 1.0 * 0.4940723 + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 2.0 * ((p * 1e-6 - 1) / (0 - 1)) ^ 2.0 * (-0.283981) + ((h * 2.016e-3 - 7214.060) / (8542.957 - 7214.060)) ^ 3.0 * 0.03646829);
    //end setState_phX;

    redeclare function extends setState_phX "Set the thermodynamic state record from p and h (X not needed)"
      protected
        Real pr;
  
      algorithm
        pr := (p - 0.01e6) / (70e6 - 0.01e6);
        state := ThermodynamicState(p = p, T = 273.3992 + ((h - 3575418.1815778962) / (5396250.379 - 3575418.1815778962)) ^ 1.0 * 77.45537 + ((h - 3575418.1815778962) / (5396250.379 - 3575418.1815778962)) ^ 2.0 * (-0.1434118) + ((p - 0.1e6) / (100e6 - 0.1e6)) ^ 1.0 * (-28.70406) + ((p - 0.1e6) / (100e6 - 0.1e6)) ^ 1.0 * ((h - 3575418.1815778962) / (5396250.379 - 3575418.1815778962)) ^ 1.0 * (-8.616032) + ((p - 0.1e6) / (100e6 - 0.1e6)) ^ 2.0 * (-23.84597) + ((p - 0.1e6) / (100e6 - 0.1e6)) ^ 2.0 * ((h - 3575418.1815778962) / (5396250.379 - 3575418.1815778962)) ^ 1.0 * 5.454366 + ((p - 0.1e6) / (100e6 - 0.1e6)) ^ 3.0 * 8.307321);
    end setState_phX;
  
    redeclare function extends pressure "Return the pressure from the thermodynamic state"
      algorithm
        p := state.p;
    end pressure;
  
    redeclare function extends temperature "Return the temperature from the thermodynamic state"
      algorithm
        T := state.T;
    end temperature;
  
    redeclare function extends density "Return the density from the thermodynamic state"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 1) / (40 - 1);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        d := 2.016e-3 * (437.0214 + Pr ^ 1.0 * 16981.67 + Pr ^ 2.0 * (-4197.979) + Pr ^ 3.0 * 570.4742 + Pr ^ 4.0 * 33.92531 + Tr ^ 1.0 * (-48.97457) + Tr ^ 1.0 * Pr ^ 1.0 * (-1859.952) + Tr ^ 1.0 * Pr ^ 2.0 * 803.5669 + Tr ^ 1.0 * Pr ^ 3.0 * (-127.3914) + Tr ^ 2.0 * 8.82671 + Tr ^ 2.0 * Pr ^ 1.0 * 180.9694 + Tr ^ 2.0 * Pr ^ 2.0 * (-74.76895) + Tr ^ 3.0 * (-2.41459) + Tr ^ 3.0 * Pr ^ 1.0 * (-8.553919));
    end density;
  
    redeclare function extends specificEnthalpy "Return the specific enthalpy from the thermodynamic state"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 1) / (40 - 1);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        h := (7214.099 + Pr ^ 1.0 * 278.1949 + Pr ^ 2.0 * 197.3857 + Pr ^ 3.0 * (-46.06233) + Pr ^ 4.0 * (-1.962117) + Tr ^ 1.0 * 861.0746 + Tr ^ 1.0 * Pr ^ 1.0 * 75.43346 + Tr ^ 1.0 * Pr ^ 2.0 * (-49.11461) + Tr ^ 1.0 * Pr ^ 3.0 * 13.45874 + Tr ^ 2.0 * 3.483872 + Tr ^ 2.0 * Pr ^ 1.0 * (-5.284725) + Tr ^ 2.0 * Pr ^ 2.0 * 2.367275) / 2.016e-3;
    end specificEnthalpy;
  
    redeclare function extends specificEntropy "Return the specific entropy from the thermodynamic state"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 1) / (40 - 1);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        s := (85.03628 + Pr ^ 1.0 * (-178.954) + Pr ^ 2.0 * 744.3632 + Pr ^ 3.0 * (-1887.247) + Pr ^ 4.0 * 2655.94 + Pr ^ 5.0 * (-1915.575) + Pr ^ 6.0 * 551.3883 + Tr ^ 1.0 * 1.67609 + Tr ^ 1.0 * Pr ^ 1.0 * 14.01634 + Tr ^ 1.0 * Pr ^ 2.0 * (-34.49786) + Tr ^ 1.0 * Pr ^ 3.0 * 24.02755 + Tr ^ 1.0 * Pr ^ 4.0 * 13.66036 + Tr ^ 1.0 * Pr ^ 5.0 * (-16.61229) + Tr ^ 2.0 * (-0.4074466) + Tr ^ 2.0 * Pr ^ 2.0 * 6.598304 + Tr ^ 2.0 * Pr ^ 3.0 * (-25.83269) + Tr ^ 2.0 * Pr ^ 4.0 * 26.80698 + Tr ^ 3.0 * Pr ^ 1.0 * (-7.367386) + Tr ^ 3.0 * Pr ^ 2.0 * 26.17667 + Tr ^ 3.0 * Pr ^ 3.0 * (-34.73876) + Tr ^ 4.0 * 2.076966 + Tr ^ 4.0 * Pr ^ 1.0 * (-5.005642) + Tr ^ 4.0 * Pr ^ 2.0 * 16.925 + Tr ^ 5.0 * Pr ^ 1.0 * (-4.216638)) / 2.016e-3;
    end specificEntropy;
  
    redeclare function extends specificInternalEnergy "Return the specific internal energy from the thermodynamic state"
      algorithm
        u := specificEnthalpy(state) - state.p / density(state.p, state.T);
    end specificInternalEnergy;
  
    redeclare function extends dynamicViscosity "Return specific heat capacity at constant volume"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 1) / (40 - 1);
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        eta := 1e-6 * (8.38385 + Pr ^ 1.0 * 0.3526271 + Pr ^ 2.0 * 1.239111 + Pr ^ 3.0 * (-0.5758682) + Pr ^ 4.0 * 0.1154501 + Tr ^ 1.0 * 0.6353407 + Tr ^ 1.0 * Pr ^ 1.0 * (-0.1219763) + Tr ^ 1.0 * Pr ^ 2.0 * (-0.1415456) + Tr ^ 1.0 * Pr ^ 3.0 * 0.06477221 + Tr ^ 2.0 * (-0.01080957) + Tr ^ 2.0 * Pr ^ 1.0 * 0.02475982 + Tr ^ 2.0 * Pr ^ 2.0 * 0.002424645 + Tr ^ 3.0 * Pr ^ 1.0 * (-0.002994656));
    end dynamicViscosity;
  
    redeclare function extends specificHeatCapacityCp "C_P/ J/kg.K"
      protected
        Real Tr, Pr;
  
      algorithm
        Pr := (state.p * 1e-6 - 1) / (40 - 1);
// Provide bounds
        Tr := (state.T - 273.15) / (303.15 - 273.15);
        cp := ((-10.56945 * Pr ^ 1.0 * Tr ^ 1.0) + 75.43346 * Pr ^ 1.0 + 4.73455 * Pr ^ 2.0 * Tr ^ 1.0 - 49.11461 * Pr ^ 2.0 + 13.45874 * Pr ^ 3.0 + 6.967744 * Tr ^ 1.0 + 861.0746) / (303.15 - 273.15) / 2.016e-3;
    end specificHeatCapacityCp;
  

  end H2_custom;

  model storage_control
    Modelica.Blocks.Interfaces.RealInput makeup_flow annotation(
      Placement(visible = true, transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}}, rotation = -90), iconTransformation(origin = {100, 120}, extent = {{-20, -20}, {20, 20}}, rotation = -90)));
    Modelica.Blocks.Interfaces.RealInput storage_pressure annotation(
      Placement(visible = true, transformation(origin = {0, 0}, extent = {{-20, -20}, {20, 20}}, rotation = -90), iconTransformation(origin = {-92, 120}, extent = {{-20, -20}, {20, 20}}, rotation = -90)));
    Modelica.Blocks.Interfaces.RealOutput storage_flow annotation(
      Placement(visible = true, transformation(origin = {-100, 0}, extent = {{-20, -20}, {20, 20}}, rotation = -90), iconTransformation(origin = {0, -120}, extent = {{-20, -20}, {20, 20}}, rotation = -90)));
  equation
    if storage_pressure > 200e5 then
      storage_flow = min(makeup_flow, 0);
    elseif storage_pressure < 100e5 then
      storage_flow = max(makeup_flow, 0);
    else
      makeup_flow = storage_flow;
    end if;
    annotation(
      Icon(graphics = {Text(origin = {-56, 10}, extent = {{-110, 184}, {10, 138}}, textString = "storage pressure"), Text(origin = {152, 8}, extent = {{-110, 184}, {10, 138}}, textString = "optimal flow"), Rectangle(origin = {-2, 0}, extent = {{-100, 100}, {100, -100}})}));
  end storage_control;
  annotation(
    uses(Modelica(version = "3.2.3")));
end Operational_Toolkit_v2;
