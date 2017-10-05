MODULE WiringPi;

	(* Oberon-Wrapper for libwiringPi.so, J. Templ 2016-09-13.

	Naming convention: The same names as in libwiringPi.so are used except for names
	that already start with wiringPi or a similar prefix because that prefix is given by the
	module name (WiringPi) anyway. 
	The underscores in names are removed. Exported names start with a capital letter.

	Warning 1: Before using WiringPi please consult http://wiringpi.com for the details.
	Inappropriate use may damage your Raspberry Pi hardware.

	Warning 2: Before starting any program based on WiringPi save all your work. Any fatal error will
	kill the running process. There is (currently) no way to get full control over the error handling
	(complaints to projects@drogon.net. *)

	IMPORT SYSTEM, Unix;

	CONST
		(* wiringPi modes *)
		MODEPINS* = 0;
		MODEGPIO* = 1;
		MODEGPIOSYS* = 2;
		MODEPHYS* = 3;
		MODEPIFACE* = 4;
		MODEUNINITIALISED* = -1;

		(* Pin modes *)
		INPUT* = 0;
		OUTPUT* = 1;
		PWMOUTPUT* = 2;
		GPIOCLOCK* = 3;
		SOFTPWMOUTPUT* = 4;
		SOFTTONEOUTPUT* = 5;
		PWMTONEOUTPUT* = 6;

		LOW* = 0;
		HIGH* = 1;

		(* Pull up/down/none *)
		PUDOFF* = 0;
		PUDDOWN* = 1;
		PUDUP* = 2;

		(* PWM *)
		PWMMODEMS* = 0;
		PWMMODEBAL* = 1;

		(* Interrupt levels *)
		INTEDGESETUP* = 0;
		INTEDGEFALLING* = 1;
		INTEDGERISING* = 2;
		INTEDGEBOTH* = 3;
	
		(* Pi model types and version numbers *)
		PIMODELA* = 0;
		PIMODELB* = 1;
		PIMODELAP* = 2;
		PIMODELBP* = 3;
		PIMODEL2* = 4;
		PIALPHA* = 5;
		PIMODELCM* = 6;
		PIMODEL07* = 7;
		PIMODEL3* = 8;
		PIMODELZERO* = 9;
		PIVERSION1* = 0;
		PIVERSION11* = 1;
		PIVERSION12* = 2;
		PIVERSION2* = 3;
		PIMAKERSONY* = 0;
		PIMAKEREGOMAN* = 1;
		PIMAKERMBEST* = 2;
		PIMAKERUNKNOWN* = 3;

		(* Failure modes *)
		FATAL* = TRUE;
		ALMOST* = FALSE;

		(* shift order *)
		LSBFIRST* = 0;
		MSBFIRST* = 1;

	TYPE
		InterruptHandler* = PROCEDURE();
		ThreadHandler* = PROCEDURE(dummy: LONGINT): LONGINT;

	VAR
		piModelNames*,
		piRevisionNames*,
		piMakerNames*: POINTER[1] TO ARRAY 16 OF POINTER [1] TO 
																							ARRAY 256 (* 0x terminated *) OF CHAR;
		piMemorySize*: POINTER[1] TO ARRAY 8 OF LONGINT;
		errno*: LONGINT;
		setupDone: BOOLEAN;

	PROCEDURE -includePi()
		"#include <wiringPi.h>";

	PROCEDURE -includeSerial()
		"#include <wiringSerial.h>";

	PROCEDURE -includePiSPI()
		"#include <wiringPiSPI.h>";

	PROCEDURE -includePiI2C()
		"#include <wiringPiI2C.h>";

	PROCEDURE -includeShift()
		"#include <wiringShift.h>";

	PROCEDURE -setupVars()
		"*(void**)&WiringPi_piModelNames = (void*)piModelNames; *(void**)&WiringPi_piRevisionNames = (void*)piRevisionNames; *(void**)&WiringPi_piMakerNames = (void*)piMakerNames; *(void**)&WiringPi_piMemorySize = (void*)piMemorySize";

	PROCEDURE -setenv(name, value: ARRAY OF CHAR; overwrite: LONGINT): LONGINT
		"(LONGINT)setenv((const char*)name, (const char*)value, overwrite);";

	PROCEDURE -unsetenv(name: ARRAY OF CHAR): LONGINT
		"(LONGINT)unsetenv((const char*)name);";

	PROCEDURE -wiringPiSetup(): LONGINT
		"(LONGINT)wiringPiSetup()";

	PROCEDURE -wiringPiSetupGpio(): LONGINT
		"(LONGINT)wiringPiSetupGpio()";

	PROCEDURE -wiringPiSetupPhys(): LONGINT
		"(LONGINT)wiringPiSetupPhys()";

	PROCEDURE -wiringPiSetupSys(): LONGINT
		"(LONGINT)wiringPiSetupSys()";

	PROCEDURE -pinModeAlt(pin, mode: LONGINT)
		"pinModeAlt(pin, mode)";

	PROCEDURE -pinMode(pin, mode: LONGINT)
		"pinMode(pin, mode)";

	PROCEDURE -pullUpDnControl(pin, pud: LONGINT)
		"pullUpDnControl(pin, pud)";

	PROCEDURE -digitalRead(pin: LONGINT): LONGINT
		"digitalRead(pin)";

	PROCEDURE -digitalWrite(pin, value: LONGINT)
		"digitalWrite(pin, value)";

	PROCEDURE -pwmWrite(pin, value: LONGINT)
		"pwmWrite(pin, value)";

	PROCEDURE -analogRead(pin: LONGINT): LONGINT
		"analogRead(pin)";

	PROCEDURE -analogWrite(pin, value: LONGINT)
		"analogWrite(pin, value)";

	PROCEDURE -delay(howLong: LONGINT)
		"delay(howLong)";

	PROCEDURE -delayMicroseconds (howLong: LONGINT)
		"delayMicroseconds(howLong)";

	PROCEDURE -millis(): LONGINT
		"millis()";

	PROCEDURE -micros(): LONGINT
		"micros()";

	PROCEDURE -piBoardRev(): LONGINT
		"piBoardRev()";

	PROCEDURE -piBoardId(VAR model, rev, mem, maker, overVolted: LONGINT)
		"piBoardId((int*)model, (int*)rev, (int*)mem, (int*)maker, (int*)overVolted)";

	PROCEDURE -wpiPinToGpio(wpiPin: LONGINT): LONGINT
		"wpiPinToGpio(wpiPin)";

	PROCEDURE -physPinToGpio(physPin: LONGINT): LONGINT
		"physPinToGpio(physPin)";

	PROCEDURE -setPadDrive(group, value: LONGINT)
		"setPadDrive(group, value)";

	PROCEDURE -getAlt(pin: LONGINT): LONGINT
		"getAlt(pin)";

	PROCEDURE -pwmToneWrite(pin, freq: LONGINT)
		"pwmToneWrite(pin, freq)";

	PROCEDURE -digitalWriteByte(value: LONGINT)
		"digitalWriteByte(value)";

	PROCEDURE -digitalReadByte(): LONGINT
		"digitalReadByte()";

	PROCEDURE -pwmSetMode(mode: LONGINT)
		"pwmSetMode(mode)";

	PROCEDURE -pwmSetRange(range: LONGINT)
		"pwmSetRange(range)";

	PROCEDURE -pwmSetClock(divisor: LONGINT)
		"pwmSetClock(divisor)";

	PROCEDURE -gpioClockSet(pin, freq: LONGINT)
		"gpioClockSet(pin, freq)";

	PROCEDURE -waitForInterrupt(pin, mS: LONGINT): LONGINT
		"waitForInterrupt(pin, mS)";

	PROCEDURE -isr(pin, mode: LONGINT; function: InterruptHandler): LONGINT
		"(LONGINT)wiringPiISR(pin, mode, function)";

	PROCEDURE -piThreadCreate(fn: ThreadHandler): LONGINT
		"(LONGINT)piThreadCreate((void *(*)(void *))fn)";

	PROCEDURE -piLock(key: LONGINT)
		"piLock(key)";

	PROCEDURE -piUnlock(key: LONGINT)
		"piUnlock(key)";

	PROCEDURE -piHiPri(pri: LONGINT): LONGINT
		"(LONGINT)piHiPri(pri)";

	PROCEDURE -serialOpen(device: ARRAY OF CHAR; baud: LONGINT): INTEGER
		"(INTEGER)serialOpen((const char *)device, (const int)baud)";

	PROCEDURE -serialClose(fd: LONGINT)
		"serialClose((const int)fd)";

	PROCEDURE -serialFlush(fd: LONGINT)
		"serialFlush((const int)fd)";

	PROCEDURE -serialPutchar(fd: LONGINT; c: CHAR)
		"serialPutchar((const int)fd, (const unsigned char)c)";

	PROCEDURE -serialPuts(fd: LONGINT; s: ARRAY OF CHAR)
		"serialPuts((const int)fd, (const char *)s)";

	PROCEDURE -serialPrintf(fd: LONGINT; message: ARRAY OF CHAR; p1, p2, p3: LONGINT)
		"serialPrintf((const int)fd, (const char *)message, p1, p2, p3)";

	PROCEDURE -serialDataAvail(fd: LONGINT): LONGINT
		"(LONGINT)serialDataAvail((const int)fd)";

	PROCEDURE -serialGetchar(fd: LONGINT): INTEGER
		"(INTEGER)serialGetchar((const int)fd)";

	PROCEDURE -wiringPiSPIGetFd(channel: LONGINT): INTEGER
		"(INTEGER)wiringPiSPIGetFd(channel)";

	PROCEDURE -wiringPiSPIDataRW(channel: LONGINT; data: ARRAY OF CHAR; len: LONGINT): LONGINT
		"wiringPiSPIDataRW(channel, data, len)";

	PROCEDURE -wiringPiSPISetupMode(channel, speed, mode: LONGINT): LONGINT
		"wiringPiSPISetupMode(channel, speed, mode)";

	PROCEDURE -wiringPiSPISetup(channel, speed: LONGINT): INTEGER
		"(INTEGER)wiringPiSPISetup(channel, speed)";

	PROCEDURE -wiringPiI2CRead(fd: LONGINT): LONGINT
		"(LONGINT)wiringPiI2CRead(fd)";

	PROCEDURE -wiringPiI2CReadReg8(fd, reg: LONGINT): INTEGER
		"(INTEGER)wiringPiI2CReadReg8(fd, reg)";

	PROCEDURE -wiringPiI2CReadReg16(fd, reg: LONGINT): LONGINT
		"(LONGINT)wiringPiI2CReadReg16(fd, reg)";

	PROCEDURE -wiringPiI2CWrite(fd, data: LONGINT): LONGINT
		"(LONGINT)wiringPiI2CWrite(fd, data)";

	PROCEDURE -wiringPiI2CWriteReg8(fd, reg, data: LONGINT): LONGINT
		"(LONGINT)wiringPiI2CWriteReg8(fd, reg, data)";

	PROCEDURE -wiringPiI2CWriteReg16(fd, reg, data: LONGINT): LONGINT
		"(LONGINT)wiringPiI2CWriteReg16(fd, reg, data)";

	PROCEDURE -wiringPiI2CSetupInterface(device: ARRAY OF CHAR; devId: LONGINT): INTEGER
		"(INTEGER)wiringPiI2CSetupInterface((const char *)device, devId)";

	PROCEDURE -wiringPiI2CSetup(devId: LONGINT): INTEGER
		"(INTEGER)wiringPiI2CSetup(devId)";

	PROCEDURE -shiftIn(dPin, cPin, order: LONGINT): INTEGER
		"(INTEGER)shiftIn((uint8_t)dPin, (uint8_t)cPin, (uint8_t)order)";

	PROCEDURE -shiftOut(dPin, cPin, order, val: LONGINT)
		"shiftOut((uint8_t)dPin, (uint8_t)cPin, (uint8_t)order, (uint8_t)val)";


	(* Turns wiringPi into a mode that returns error codes for fatal errors. Otherwise, 
	which is the default, the process is terminated and an error message is shown on the console.
	Missing admin rights in setup always terminates the process. *)
	PROCEDURE UseErrorCodesOn*;
		VAR res: LONGINT;
	BEGIN
		res := setenv("WIRINGPI_CODES", "1", 1);
		IF res # 0 THEN HALT(20) END
	END UseErrorCodesOn;

	(* Turns wiringPi into a mode that does not return error codes for fatal errors.. This is the default mode.
	Missing admin rights in setup always terminates the process. *)
	PROCEDURE UseErrorCodesOff*;
		VAR res: LONGINT;
	BEGIN
		res := unsetenv("WIRINGPI_CODES");
		IF res # 0 THEN HALT(20) END
	END UseErrorCodesOff;

	(* wiringPi setup functions; http://wiringpi.com/reference/setup/
	one and only one must be called; defines the pin numbering schema;
	terminates the process if called repeatedly, so we have to protect it. *)

	PROCEDURE Setup*();	(* requires admin rights *)
		VAR res: LONGINT;
	BEGIN
		IF ~setupDone THEN res := wiringPiSetup();
			IF res = 0 THEN setupDone := TRUE ELSE errno := Unix.errno(); HALT(22) END
		ELSE HALT(21)
		END
	END Setup;

	PROCEDURE SetupGpio*();	(* requires admin rights *)
		VAR res: LONGINT;
	BEGIN
		IF ~setupDone THEN res := wiringPiSetupGpio();
			IF res = 0 THEN setupDone := TRUE ELSE errno := Unix.errno(); HALT(22) END
		ELSE HALT(21)
		END
	END SetupGpio;

	PROCEDURE SetupPhys*();	(* requires admin rights *)
		VAR res: LONGINT;
	BEGIN
		IF ~setupDone THEN res := wiringPiSetupPhys();
			IF res = 0 THEN setupDone := TRUE ELSE errno := Unix.errno(); HALT(22) END
		ELSE HALT(21)
		END
	END SetupPhys;

	PROCEDURE SetupSys*();	(* does not require admin rights *)
		VAR res: LONGINT;
	BEGIN
		IF ~setupDone THEN res := wiringPiSetupSys();
			IF res = 0 THEN setupDone := TRUE ELSE errno := Unix.errno(); HALT(22) END
		ELSE HALT(21)
		END
	END SetupSys;


	(* Core wiringPi functions; http://wiringpi.com/reference/core-functions/
	pin numbering depends on setup *)

	PROCEDURE PinModeAlt*(pin, mode: LONGINT);
	BEGIN pinModeAlt(pin, mode)
	END PinModeAlt;

	PROCEDURE PinMode*(pin, mode: LONGINT);
	BEGIN pinMode(pin, mode)
	END PinMode;

	PROCEDURE PullUpDnControl*(pin, pud: LONGINT);
	BEGIN pullUpDnControl(pin, pud)
	END PullUpDnControl;

	PROCEDURE DigitalRead*(pin: LONGINT): LONGINT;
	BEGIN RETURN digitalRead(pin)
	END DigitalRead;

	PROCEDURE DigitalWrite*(pin, value: LONGINT);
	BEGIN digitalWrite(pin, value)
	END DigitalWrite;

	PROCEDURE PwmWrite*(pin, value: LONGINT);
	BEGIN pwmWrite(pin, value)
	END PwmWrite;

	PROCEDURE AnalogRead*(pin: LONGINT): LONGINT;
	BEGIN RETURN analogRead(pin)
	END AnalogRead;

	PROCEDURE AnalogWrite*(pin, value: LONGINT);
	BEGIN analogWrite(pin, value)
	END AnalogWrite;


	(* On-Board Raspberry Pi hardware specific stuff; 
	http://wiringpi.com/reference/raspberry-pi-specifics/ *)

	PROCEDURE PiBoardRev*(): LONGINT;
	BEGIN RETURN piBoardRev()
	END PiBoardRev;

	(* model, rev, mem, maker are indexes to related global tables *)
	PROCEDURE PiBoardId*(VAR model, rev, mem, maker, overVolted: LONGINT);
	BEGIN piBoardId(model, rev, mem, maker, overVolted);
	END PiBoardId;

	PROCEDURE PinToGpio*(wpiPin: LONGINT): LONGINT;
	BEGIN RETURN wpiPinToGpio(wpiPin)
	END PinToGpio;

	PROCEDURE PhysPinToGpio*(physPin: LONGINT): LONGINT;
	BEGIN RETURN physPinToGpio(physPin)
	END PhysPinToGpio;

	PROCEDURE SetPadDrive*(group, value: LONGINT);
	BEGIN setPadDrive(group, value)
	END SetPadDrive;

	PROCEDURE GetAlt*(pin: LONGINT): LONGINT;
	BEGIN RETURN getAlt(pin)
	END GetAlt;

	PROCEDURE PwmToneWrite*(pin, freq: LONGINT);
	BEGIN pwmToneWrite(pin, freq)
	END PwmToneWrite;

	PROCEDURE DigitalWriteByte*(value: LONGINT);
	BEGIN digitalWriteByte(value)
	END DigitalWriteByte;

	PROCEDURE DigitalReadByte*(): LONGINT;
	BEGIN RETURN digitalReadByte()
	END DigitalReadByte;

	PROCEDURE PwmSetMode*(mode: LONGINT);
	BEGIN pwmSetMode(mode)
	END PwmSetMode;

	PROCEDURE PwmSetRange*(range: LONGINT);
	BEGIN pwmSetRange(range)
	END PwmSetRange;

	PROCEDURE PwmSetClock*(divisor: LONGINT);
	BEGIN pwmSetClock(divisor)
	END PwmSetClock;

	PROCEDURE GpioClockSet*(pin, freq: LONGINT);
	BEGIN gpioClockSet(pin, freq)
	END GpioClockSet;


	(* Interrupts, Threads, Priority; http://wiringpi.com/reference/priority-interrupts-and-threads/
	use with care! Oberon is single threaded *)

	PROCEDURE WaitForInterrupt*(pin, mS: LONGINT): LONGINT;
	BEGIN RETURN waitForInterrupt(pin, mS)
	END WaitForInterrupt;

	PROCEDURE ISR*(pin, mode: LONGINT; function: InterruptHandler): LONGINT;
	BEGIN RETURN isr(pin, mode, function)
	END ISR;

	PROCEDURE PiThreadCreate*(fn: ThreadHandler): LONGINT;
	BEGIN RETURN piThreadCreate(fn)
	END PiThreadCreate;

	PROCEDURE PiLock*(key: LONGINT);
	BEGIN piLock(key)
	END PiLock;

	PROCEDURE PiUnlock*(key: LONGINT);
	BEGIN PiUnlock(key)
	END PiUnlock;

	PROCEDURE PiHiPri*(pri: LONGINT): LONGINT;
	BEGIN RETURN piHiPri(pri)
	END PiHiPri;


	(* Arduino style timing functions; http://wiringpi.com/reference/timing/
	also need a setup being called first *)

	PROCEDURE Delay*(howLong: LONGINT);
	BEGIN delay(howLong)
	END Delay;

	PROCEDURE DelayMicroseconds*(howLong: LONGINT);
	BEGIN delayMicroseconds(howLong)
	END DelayMicroseconds;

	PROCEDURE Millis*(): LONGINT;
	BEGIN RETURN millis()
	END Millis;

	PROCEDURE Micros*(): LONGINT;
	BEGIN RETURN micros()
	END Micros;


	(* Handle a serial port; http://wiringpi.com/reference/serial-library/ *)

	PROCEDURE SerialOpen*(device: ARRAY[1] OF CHAR; baud: LONGINT): INTEGER;
	BEGIN RETURN serialOpen(device, baud)
	END SerialOpen;

	PROCEDURE SerialClose*(fd: LONGINT);
	BEGIN serialClose(fd)
	END SerialClose;

	PROCEDURE SerialFlush*(fd: LONGINT);
	BEGIN serialFlush(fd)
	END SerialFlush;

	PROCEDURE SerialPutchar*(fd: LONGINT; c: CHAR);
	BEGIN serialPutchar(fd, c)
	END SerialPutchar;

	PROCEDURE SerialPuts*(fd: LONGINT; s: ARRAY[1] OF CHAR);
	BEGIN serialPuts(fd, s)
	END SerialPuts;

	PROCEDURE SerialPrintf*(fd: LONGINT; message: ARRAY[1] OF CHAR; p1, p2, p3: LONGINT);
	BEGIN serialPrintf(fd, message, p1, p2, p3)
	END SerialPrintf;

	PROCEDURE SerialDataAvail*(fd: LONGINT): LONGINT;
	BEGIN RETURN serialDataAvail(fd)
	END SerialDataAvail;

	PROCEDURE SerialGetchar*(fd: LONGINT): INTEGER;
	BEGIN RETURN serialGetchar(fd)
	END SerialGetchar;


	(* Simplified SPI access routines; http://wiringpi.com/reference/spi-library/ *)

	PROCEDURE SPIGetFd*(channel: LONGINT): INTEGER;
	BEGIN RETURN wiringPiSPIGetFd(channel)
	END SPIGetFd;

	PROCEDURE SPIDataRW*(channel: LONGINT; data: ARRAY[1] OF CHAR; len: LONGINT): LONGINT;
	BEGIN RETURN wiringPiSPIDataRW(channel, data, len)
	END SPIDataRW;

	PROCEDURE SPISetupMode*(channel, speed, mode: LONGINT): LONGINT;
	BEGIN RETURN wiringPiSPISetupMode(channel, speed, mode)
	END SPISetupMode;

	PROCEDURE SPISetup*(channel, speed: LONGINT): INTEGER;
	BEGIN RETURN wiringPiSPISetup(channel, speed)
	END SPISetup;


	(* Simplified I2C access routines; http://wiringpi.com/reference/i2c-library/ *)

	PROCEDURE I2CRead*(fd: LONGINT): LONGINT;
	BEGIN RETURN wiringPiI2CRead(fd)
	END I2CRead;

	PROCEDURE I2CReadReg8*(fd, reg: LONGINT): INTEGER;
	BEGIN RETURN wiringPiI2CReadReg8(fd, reg)
	END I2CReadReg8;

	PROCEDURE I2CReadReg16*(fd, reg: LONGINT): LONGINT;
	BEGIN RETURN wiringPiI2CReadReg16(fd, reg)
	END I2CReadReg16;

	PROCEDURE I2CWrite*(fd, data: LONGINT): LONGINT;
	BEGIN RETURN wiringPiI2CWrite(fd, data)
	END I2CWrite;

	PROCEDURE I2CWriteReg8*(fd, reg, data: LONGINT): LONGINT;
	BEGIN RETURN wiringPiI2CWriteReg8(fd, reg, data)
	END I2CWriteReg8;

	PROCEDURE I2CWriteReg16*(fd, reg, data: LONGINT): LONGINT;
	BEGIN RETURN wiringPiI2CWriteReg16(fd, reg, data)
	END I2CWriteReg16;

	PROCEDURE I2CSetupInterface*(device: ARRAY[1] OF CHAR; devId: LONGINT): LONGINT;
	BEGIN RETURN wiringPiI2CSetupInterface(device, devId)
	END I2CSetupInterface;

	PROCEDURE I2CSetup*(devId: LONGINT): INTEGER;
	BEGIN RETURN wiringPiI2CSetup(devId)
	END I2CSetup;


	(* Emulate some of the Arduino wiring functionality; 
	http://wiringpi.com/reference/shift-library/ *)

	PROCEDURE ShiftIn*(dPin, cPin, order: LONGINT): INTEGER;
	BEGIN RETURN shiftIn(dPin, cPin, order)
	END ShiftIn;

	PROCEDURE ShiftOut*(dPin, cPin, order, val: LONGINT);
	BEGIN shiftOut(dPin, cPin, order, val)
	END ShiftOut;

BEGIN
	setupVars();
END WiringPi.
