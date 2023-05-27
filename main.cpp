#include <iostream>

#include "version.h"

int main(int, char**) {
  std::cout << "v" << (int)VERSION_YEAR << "." << (int)VERSION_MONTH << "."
            << (int)VERSION_REVISION << " " << VERSION_HASH << "\n";
}
