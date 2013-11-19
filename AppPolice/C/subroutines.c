//
//  subroutines.c
//  Ishimura
//
//  Created by Maksym on 5/20/13.
//  Copyright (c) 2013 Maksym Stefanchuk. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "subroutines.h"


void *xmalloc(size_t size) {
	register void *value = malloc(size);
	if (value == 0) {
		fputs("Virtual memory exhausted", stderr);
		exit(EXIT_FAILURE);
	}
	return value;
}
