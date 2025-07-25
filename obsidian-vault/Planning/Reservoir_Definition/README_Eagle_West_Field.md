# Eagle West Field - Reservoir Simulation Technical Reference
## Master Index and Technical Documentation

---

## PURPOSE OF THIS DOCUMENTATION

This comprehensive technical reference defines the **Eagle West Field** reservoir parameters for advanced 3D, 3-phase reservoir simulation using MRST. The documentation provides all technical specifications and parameters needed for reservoir simulation studies following professional reservoir engineering standards.

---

## FIELD OVERVIEW AT A GLANCE

| **Parameter** | **Value** | **Units** | **Notes** |
|---------------|-----------|-----------|-----------|
| **Field Name** | Eagle West Field | - | Reservoir simulation case study |
| **Field Type** | Sandstone waterflood | - | 3-phase simulation model |
| **Reservoir Pressure** | 2,900 | psi | Initial reservoir pressure |
| **Depth** | 7,900 - 8,138 | ft TVDSS | 238 ft gross thickness |
| **API Gravity** | 32° | API | Light crude oil |
| **Temperature** | 176 | °F | Reservoir temperature |

---

## DOCUMENT STRUCTURE & NAVIGATION

### **Phase 1: Geological & Structural Framework**
```
00_Overview.md              ← START HERE (Technical Summary)
01_Structural_Geology.md    ← Grid structure, faults, layers
02_Rock_Properties.md       ← Porosity, permeability distributions
```

### **Phase 2: Fluid & Flow Characterization**
```
03_Fluid_Properties.md      ← PVT tables, phase behavior
04_SCAL_Properties.md       ← Relative permeability, capillary pressure
```

### **Phase 3: Wells & Simulation Configuration**
```
05_Wells_Completions.md     ← Well specifications, completion data
06_Production_History.md    ← Reference production profiles
```

### **Phase 4: Simulation Setup**
```
07_Initialization.md        ← Initial conditions, equilibration
08_MRST_Implementation.md   ← Complete simulation workflow
09_Volumetrics_Reserves.md  ← STOIIP calculations, material balance
```

---

## HOW TO USE THIS DOCUMENTATION

### **For Reservoir Engineers:**
1. **Start with** `00_Overview.md` for technical context
2. **Review** geological framework (`01_Structural_Geology.md`)
3. **Understand** rock and fluid properties (`02-04`)
4. **Configure** well specifications (`05-06`)
5. **Setup** simulation parameters (`07-09`)

### **For Simulation Engineers:**
1. **Quick Start:** Jump to `08_MRST_Implementation.md`
2. **Input Data:** Reference sections 01-07 for parameters
3. **Validation:** Use `09_Volumetrics_Reserves.md` for material balance
4. **Forward Simulation:** Follow technical workflow

### **For Technical Teams:**
1. **Overview:** Use `00_Overview.md` for technical summary
2. **Volumetrics:** Reference `09_Volumetrics_Reserves.md`
3. **Well Config:** Review `05_Wells_Completions.md`
4. **Quality Control:** Check validation procedures throughout

---

## KEY SIMULATION OBJECTIVES

### **Primary Goals:**
- **Forward Simulation:** Model reservoir performance under waterflood
- **Waterflood Optimization:** Analyze sweep efficiency patterns
- **Well Configuration:** Evaluate 4 producers + 3 injectors setup
- **Technical Assessment:** Flow simulation and pressure distribution

### **Technical Focus Areas:**
- **Flow Patterns:** Multi-phase flow through heterogeneous reservoir
- **Compartmentalization:** 5 major faults affecting fluid flow
- **Pressure Dynamics:** Injection/production pressure balance
- **Recovery Mechanisms:** Primary and secondary recovery simulation

---

## DOCUMENT CROSS-REFERENCES

### **Critical Dependencies:**
- **Grid Design** (`01`) → **MRST Setup** (`08`)
- **Rock Properties** (`02`) → **Initialization** (`07`)
- **Fluid PVT** (`03`) → **MRST Implementation** (`08`)
- **SCAL Data** (`04`) → **Relative Permeability Setup** (`08`)
- **Well Data** (`05`) → **Well Modeling** (`08`)
- **Production Profiles** (`06`) → **Forward Simulation** (`08`)

### **Quality Control Chain:**
- **Volumetrics** (`09`) validates **Rock Properties** (`02`)
- **Material Balance** (`09`) validates **Fluid Properties** (`03`)
- **Well Configuration** (`05`) validates **Completion Design**
- **Initial Conditions** (`07`) validates **Reservoir State**

---

## IMPLEMENTATION WORKFLOW

### **Phase 1: Model Building**
```
Grid Setup → Rock Properties → Fluid Properties → Well Placement
```
- Use `01_Structural_Geology.md` for grid design
- Apply `02_Rock_Properties.md` for heterogeneity
- Implement `03_Fluid_Properties.md` PVT tables
- Configure `05_Wells_Completions.md` specifications

### **Phase 2: Initialization**
```
Equilibration → Contacts → Initial State → Validation
```
- Follow `07_Initialization.md` procedures
- Validate with `09_Volumetrics_Reserves.md`

### **Phase 3: Forward Simulation**
```
Base Case → Production Simulation → Pressure Analysis → Results
```
- Reference data from `06_Production_History.md`
- Use `08_MRST_Implementation.md` workflow

### **Phase 4: Technical Analysis**
```
Simulation Results → Flow Analysis → Performance Evaluation
```
- Analysis using `09_Volumetrics_Reserves.md` methods

---

## DATA QUALITY & VALIDATION

### **High Confidence Data:**
- **Well Logs** - Complete petrophysical suite
- **PVT Analysis** - Laboratory fluid studies
- **SCAL Data** - Core analysis measurements
- **Structural Framework** - Seismic interpretation

### **Medium Confidence Data:**
- **Fault Properties** - Limited transmissibility data
- **Aquifer Parameters** - Analytical model assumptions
- **Production Profiles** - Reference case scenarios

### **Model Validation Requirements:**
- **Material Balance** - Volumetric consistency checks
- **Pressure Initialization** - Equilibration validation
- **Flow Validation** - Multi-phase flow verification

---

## TECHNICAL RESOURCES

### **For New Users:**
1. **Technical Overview:** Review `00_Overview.md`
2. **MRST Setup:** Start with `08_MRST_Implementation.md`
3. **Simulation Context:** Read `06_Production_History.md`

### **For Advanced Users:**
1. **Uncertainty Analysis:** Study methods in `09_Volumetrics_Reserves.md`
2. **Advanced Properties:** Review topics in `02_Rock_Properties.md`
3. **Multi-phase Flow:** Advanced concepts in `04_SCAL_Properties.md`

---

## DOCUMENT MAINTENANCE

### **Last Updated:** January 25, 2025
### **Version:** 1.0
### **Next Review:** July 25, 2025

### **Change Log:**
- **v1.0 (Jan 2025):** Initial technical reference documentation
- **Future:** Updates based on simulation validation and technical review

### **Document Ownership:**
- **Technical Lead:** Reservoir Simulation Team
- **MRST Support:** Simulation Engineering Team  
- **Quality Control:** Technical Review Team

---

## QUICK START CHECKLIST

### **Before Your First Simulation:**
- [ ] Read `00_Overview.md` for technical overview
- [ ] Review `08_MRST_Implementation.md` for setup workflow
- [ ] Validate STOIIP calculation using `09_Volumetrics_Reserves.md`
- [ ] Check MRST module requirements
- [ ] Confirm grid setup parameters

### **For Forward Simulation:**
- [ ] Configure well specifications from `05_Wells_Completions.md`
- [ ] Set up PVT tables from `03_Fluid_Properties.md`
- [ ] Initialize reservoir state using `07_Initialization.md`
- [ ] Reference production profiles from `06_Production_History.md`

### **For Technical Studies:**
- [ ] Review simulation scenarios in `09_Volumetrics_Reserves.md`
- [ ] Plan sensitivity cases using uncertainty ranges
- [ ] Set up technical validation framework

---

## TECHNICAL GUIDELINES

1. **Always validate material balance** before proceeding with simulation studies
2. **Use uncertainty ranges** for robust technical analysis
3. **Cross-check parameters** between documents for consistency
4. **Document assumptions** when deviating from base case
5. **Regular quality control** using validation procedures

---

**Links to All Documents:**
- [Overview](./00_Overview.md) | [Geology](./01_Structural_Geology.md) | [Rock Props](./02_Rock_Properties.md) | [Fluids](./03_Fluid_Properties.md) | [SCAL](./04_SCAL_Properties.md)
- [Wells](./05_Wells_Completions.md) | [Production](./06_Production_History.md) | [Initialize](./07_Initialization.md) | [MRST](./08_MRST_Implementation.md) | [Volumetrics](./09_Volumetrics_Reserves.md)

---
*Eagle West Field Technical Reference - Reservoir Simulation Documentation*