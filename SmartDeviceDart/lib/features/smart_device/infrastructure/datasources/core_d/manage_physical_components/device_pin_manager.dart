import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/device_configuration_base_class.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/nano_pi_duo2_configuration/nano_pi_duo2_configuration.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/nano_pi_neo/nano_pi_neo_configuration.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/nano_pi_neo2/nano_pi_neo2_configuration.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/nano_pi_neo_air/nano_pi_neo_air_configuration.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/pin_information.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/devices_pin_configuration_u/raspberry_pi3_model_b_rev_1_2/raspberry_pi3_model_b_rev_1_2_configuration.dart';
import 'package:smart_device_dart/features/smart_device/application/usecases/smart_device_objects_u/abstracts_devices/smart_device_base_abstract.dart';
import 'package:smart_device_dart/features/smart_device/domain/entities/core_e/enums_e.dart';
import 'package:smart_device_dart/features/smart_device/infrastructure/datasources/system_commands_d/system_commands_manager_d.dart';

///  This class save all the configuration of the pins per device,
///  every device have different pin for each task,
///  and these class will give the correct pin for the task.
///  Also these class will manage unused pins for new connections and
///  will return free pins number for the required task.

///  Also these class manage the pins,
///  and check if this pin is in the type that the user needs (gpio and more),
///  If pin is not in use and in the correct type that user expect it return the
///  number of the pin, else return -1

abstract class DevicePinListManagerAbstract {
  ///  Will save the type of the current physical device
  static PhysicalDeviceType physicalDeviceType;

  ///  Will save the current physical device pin configuration
  static DeviceConfigurationBaseClass physicalDevice;

  Future setPhysicalDeviceTypeByHostName();

  /// Return a list of free pins that are not taken, the list will consist of
  /// the different pins types depending on the smart device type needed pins
  List<PinInformation> getFreePinsForSmartDeviceType(DeviceType deviceType);

  /// Return a list of free gpio pins that are not taken
  PinInformation getFreeGpioPins({List<PinInformation> ignorePinsList});

  PinInformation getGpioPin(int pinNumber);

  PhysicalDeviceType convertPhysicalDeviceTypeStringToPhysicalDeviceTypeObject(
      String physicalDeviceType);
}

class DevicePinListManager extends DevicePinListManagerAbstract {
  ///  Will save the type of the current physical device
  static PhysicalDeviceType physicalDeviceType;

  ///  Will save the current physical device pin configuration
  static DeviceConfigurationBaseClass physicalDevice;

  @override
  Future setPhysicalDeviceTypeByHostName() async {
    final SystemCommandsManager systemCommandsManager = SystemCommandsManager();
    String deviceHostName = await systemCommandsManager.getDeviceHostName();
    deviceHostName = deviceHostName.replaceAll('-', '').replaceAll(' ', '');

    physicalDeviceType =
        convertPhysicalDeviceTypeStringToPhysicalDeviceTypeObject(
            deviceHostName);

    String raspberryPiVersion =
        await systemCommandsManager.getRaspberryPiDeviceVersion();

    if (physicalDeviceType == null &&
        raspberryPiVersion != null &&
        raspberryPiVersion
            .toLowerCase()
            .contains('Raspberry_Pi'.toLowerCase())) {
      physicalDeviceType = PhysicalDeviceType.RaspberryPi;
    }

    print('phys type is $physicalDeviceType');
    //  Save the current physical device configuration to the
    //  physicalDevice variable
    switch (physicalDeviceType) {
      case PhysicalDeviceType.NanoPiDuo2:
        {
          physicalDevice = NanoPiDuo2Configuration();
          break;
        }
      case PhysicalDeviceType.NanoPiAir:
        {
          physicalDevice = NanoPiNEOAirConfiguration();
          break;
        }
      case PhysicalDeviceType.NanoPiNeo:
        {
          physicalDevice = NanoPiNeoConfiguration();
          break;
        }
      case PhysicalDeviceType.NanoPiNeo2:
        {
          physicalDevice = NanoPiNeo2Configuration();
          break;
        }
      case PhysicalDeviceType.RaspberryPi:
        {
          RaspberryPiType raspberryPiType =
              EnumHelper.stringToRaspberryPiType(raspberryPiVersion);

          switch (raspberryPiType) {
            case RaspberryPiType.Raspberry_Pi_3_Model_B_Rev_1_2:
              {
                print('Raspberry Pi 3 Model B Rev 1.2 found');
                physicalDevice = RaspberryPi3ModelBRev1_2Configuration();
                break;
              }
            case RaspberryPiType.Raspberry_Pi_4_Model_B_Rev_1_4:
              {
                print('Raspberry Pi 4 Model B Rev 1.4 found');
                // Have same pin configuration as Pi 3
                physicalDevice = RaspberryPi3ModelBRev1_2Configuration();
                break;
              }
            default:
              {
                print('Raspberry pi $raspberryPiVersion is not supported');
                print('The software will not be able to control the pins');
                break;
              }
          }
          break;
        }
      default:
        {
          print('Detected deviceHostName $deviceHostName \n'
              'Device is not supported, the software will not be able to '
              'control the pins.');
          break;
        }
    }
    print('This device is of type:'
        ' ${EnumHelper.physicalDeviceTypeToString(physicalDeviceType)}');
  }

  ///  Ask for gpio pin, if free return the pin number,
  ///  else return error number (negative numbers)
  @override
  PinInformation getGpioPin(int pinNumber) {
    if (physicalDevice == null) {
      print('Error physical device is null');
      return null;
    }
    try {
      final int isGpioFree = physicalDevice.isGpioPinFree(pinNumber);
      if (isGpioFree != 0) {
        print('Gpio $pinNumber is not free, exist with error code $isGpioFree');
        return null;
      }

      final PinInformation pinInformation =
          physicalDevice.getGpioPin(pinNumber);

      return pinInformation;
    } catch (e) {
      print('This is the exception: $e');
      return null;
    }
  }

  ///  Return physicalDeviceType object if
  ///  string physicalDeviceType exist (in general) else return null
  @override
  PhysicalDeviceType convertPhysicalDeviceTypeStringToPhysicalDeviceTypeObject(
      String physicalDeviceType) {
    //  Loop through all the physical devices types
    for (final PhysicalDeviceType physicalDeviceTypeTemp
        in PhysicalDeviceType.values) {
      if (EnumHelper.physicalDeviceTypeToString(physicalDeviceTypeTemp)
              .toLowerCase() ==
          physicalDeviceType.toLowerCase()) {
        return physicalDeviceTypeTemp; //  If physicalDeviceType string exist
        // return the physicalDeviceType enum object
      }
    }
    return null;
  }

  @override
  List<PinInformation> getFreePinsForSmartDeviceType(DeviceType deviceType) {
    final dynamic smartDeviceBaseAbstract =
        EnumHelper.deviceTypeToSmartDeviceBaseAbstractObject(deviceType);

    final List<String> neededPinTypesList =
        (smartDeviceBaseAbstract as SmartDeviceBaseAbstract)
            .getNeededPinTypesList();

    final List<PinInformation> pinInformationList = <PinInformation>[];

    for (final String pinType in neededPinTypesList) {
      if (pinType.toLowerCase() == 'gpio') {
        pinInformationList
            .add(getFreeGpioPins(ignorePinsList: pinInformationList));
      } else {
        throw UnimplementedError();
      }
    }

    return pinInformationList;
  }

  @override
  PinInformation getFreeGpioPins({List<PinInformation> ignorePinsList}) {
    return physicalDevice?.getNextFreeGpioPin(ignorePinsList: ignorePinsList);
  }
}

class DevicePinListManagerPC extends DevicePinListManagerAbstract {
  ///  Will save the type of the current physical device
  static PhysicalDeviceType physicalDeviceType;

  ///  Will save the current physical device pin configuration
  static DeviceConfigurationBaseClass physicalDevice;

  @override
  PhysicalDeviceType convertPhysicalDeviceTypeStringToPhysicalDeviceTypeObject(
      String physicalDeviceType) {
    //  Loop through all the physical devices types
    for (final PhysicalDeviceType physicalDeviceTypeTemp
        in PhysicalDeviceType.values) {
      if (EnumHelper.physicalDeviceTypeToString(physicalDeviceTypeTemp)
              .toLowerCase() ==
          physicalDeviceType.toLowerCase()) {
        return physicalDeviceTypeTemp; //  If physicalDeviceType string exist
        // return the physicalDeviceType enum object
      }
    }
    return null;
  }

  @override
  PinInformation getGpioPin(int pinNumber) {
    return PinInformation();
  }

  @override
  Future<String> setPhysicalDeviceTypeByHostName() {
    return Future<String>.value('PC');
  }

  @override
  List<PinInformation> getFreePinsForSmartDeviceType(DeviceType deviceType) {
    print('Computer does not give free pins, only smart device');
    throw UnimplementedError();
  }

  @override
  PinInformation getFreeGpioPins({List<PinInformation> ignorePinsList}) {
    print('Computer does not give free gpio pins, only smart device');
    throw UnimplementedError();
  }
}
