//
//  HEHunter.h
//  Hunter's Edge
//
//  Created by James Forkey on 2/8/12.
//  Copyright (c) 2013 HF Development. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <Parse/Parse.h>

@interface HEHunter : NSObject <MKAnnotation>

//@protocol MKAnnotation <NSObject>

// Center latitude and longitude of the annotion view.
// The implementation of this property must be KVO compliant.
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

// @optional
// Title and subtitle for use by selection UI.
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *subtitle;
// @end

// Other properties:
@property (nonatomic, readonly, strong) PFObject *object;
@property (nonatomic, readonly, strong) PFGeoPoint *geopoint;
@property (nonatomic, readonly, strong) PFUser *user;
@property (nonatomic, assign) BOOL animatesDrop;
@property (nonatomic, readonly) MKPinAnnotationColor pinColor;

// Designated initializer.
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate andTitle:(NSString *)title andSubtitle:(NSString *)subtitle;
- (id)initWithPFObject:(PFObject *)object;
- (BOOL)equalToHunter:(HEHunter *)aHunter;

- (void)setTitleAndSubtitleOutsideDistance:(BOOL)outside;

@end
