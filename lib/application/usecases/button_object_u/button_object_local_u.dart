import 'package:cbj_smart_device/application/usecases/button_object_u/button_object_local_abstract.dart';
import 'package:cbj_smart_device/application/usecases/devices_pin_configuration_u/pin_information.dart';
import 'package:cbj_smart_device/application/usecases/smart_device_objects_u/abstracts_devices/smart_device_base.dart';
import 'package:cbj_smart_device/application/usecases/smart_device_objects_u/simple_devices/boiler_object.dart';
import 'package:cbj_smart_device/application/usecases/smart_device_objects_u/static_devices/blinds_object.dart';
import 'package:cbj_smart_device/infrastructure/gen/cbj_smart_device_server/protoc_as_dart/cbj_smart_device_server.pbgrpc.dart';

class ButtonObjectLocalU extends ButtonObjectLocalAbstract {
  @override
  Future<void> buttonPressed(
    SmartDeviceBase smartDevice,
    PinInformation buttonPinNumber,
    PinInformation lightPin,
  ) async {
    int errorCounter = 0;

    try {
      while (true) {
        final int returnValue =
            await buttonObjectRepository!.listenToButtonPress(buttonPinNumber);

        if (returnValue < 0) {
          errorCounter++;
          if (errorCounter > 10) {
            print('Stop the listening to the button, it failed more than '
                '$errorCounter times');
          }
          return;
        }

        if (lightPin.v == 1) {
          await smartDevice.executeDeviceAction(
            CbjDeviceActions.off,
            CbjDeviceStateGRPC.waitingInComp,
          );
        } else {
          await smartDevice.executeDeviceAction(
            CbjDeviceActions.on,
            CbjDeviceStateGRPC.waitingInComp,
          );
        }

        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (error) {
      print('Path/argument 1 is not specified');
      print('error: $error');
    }
  }

  @override
  Future<void> buttonPressedForBoiler(
    BoilerObject boilerObject,
    PinInformation buttonPinNumber,
    PinInformation boiler,
  ) async {
    int errorCounter = 0;

    try {
      while (true) {
        final int returnValue =
            await buttonObjectRepository!.listenToButtonPress(buttonPinNumber);
        print('Boiler button number $buttonPinNumber was pressed');

        if (returnValue < 0) {
          errorCounter++;
          if (errorCounter > 10) {
            print('Stop the listening to the button, it failed more than '
                '$errorCounter times');
          }
          return;
        }

        if (boiler.v == 1) {
          await boilerObject.executeDeviceAction(
            CbjDeviceActions.off,
            CbjDeviceStateGRPC.waitingInComp,
          );
        } else {
          await boilerObject.executeDeviceAction(
            CbjDeviceActions.on,
            CbjDeviceStateGRPC.waitingInComp,
          );
        }

        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (error) {
      print('Path/argument 1 is not specified');
      print('error: $error');
    }
  }

  ///  Listen to two buttons but work only if one is pressed.
  @override
  Future<void> listenToTwoButtonPressedButtOnlyOneCanBePressedAtATime(
    BlindsObject smartDevice,
    PinInformation firstButtonPinNumber,
    PinInformation firstBlindsPin,
    PinInformation secondButtonPinNumber,
    PinInformation secondBlindsPin,
  ) async {
    listenToButtonPressAndChangeBlindStateAccordingly(
      smartDevice,
      firstButtonPinNumber,
      firstBlindsPin,
      secondBlindsPin,
      1,
    );

    listenToButtonPressAndChangeBlindStateAccordingly(
      smartDevice,
      secondButtonPinNumber,
      firstBlindsPin,
      secondBlindsPin,
      2,
    );
  }

  @override
  Future<void> listenToButtonPressAndChangeBlindStateAccordingly(
    BlindsObject blindsObject,
    PinInformation buttonPinNumber,
    PinInformation firstLightPin,
    PinInformation secondLightPin,
    int buttonNumber,
  ) async {
    while (true) {
      await buttonObjectRepository!
          .listenToButtonPress(buttonPinNumber)
          .then((int exitCode) async {
        print('Blind button number $buttonNumber was pressed');
        await changeBlindsPinsOutput(
          blindsObject,
          firstLightPin,
          secondLightPin,
          buttonNumber,
        );
      });
    }
  }

  ///  Logic of two buttons that cannot be pressed together
  @override
  Future<void> changeBlindsPinsOutput(
    BlindsObject blindsObject,
    PinInformation firstBlindsPin,
    PinInformation secondBlindsPin,
    int buttonPressNumber,
  ) async {
    if (firstBlindsPin.v == 1 || secondBlindsPin.v == 1) {
      firstBlindsPin.onDuration = 0;
      await blindsObject.executeDeviceAction(
        CbjDeviceActions.stop,
        CbjDeviceStateGRPC.waitingInComp,
      );
    } else if (buttonPressNumber == 1) {
      await blindsObject.executeDeviceAction(
        CbjDeviceActions.moveUp,
        CbjDeviceStateGRPC.waitingInComp,
      );
    } else if (buttonPressNumber == 2) {
      await blindsObject.executeDeviceAction(
        CbjDeviceActions.moveDown,
        CbjDeviceStateGRPC.waitingInComp,
      );
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }
}
